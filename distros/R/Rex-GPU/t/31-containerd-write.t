use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# configure_containerd end to end against a scripted host (karr #63): the
# dispatch, the karr #13 heal, the present/v3/v2 writes and the standalone
# containerd path. t/30 and t/70 test the pure decisions; this test pins what
# configure_containerd hands Rex once they are made (goldens under
# t/golden/containerd/).
#
# CLAIMS, for rke2 and k3s alike (only the /var/lib/rancher/<dist> base
# differs):
#   * the bare 0.002 clobber config.toml.tmpl => `rm -f` of that file, the v3
#     drop-in, two warnings; config.toml is not read;
#   * a v2 config.toml (containerd 1.x) => base-extending config.toml.tmpl;
#   * a v3 config.toml, or one that only imports config-v3.toml.d => the v3
#     drop-in under config-v3.toml.d/;
#   * a config.toml that already carries an nvidia runtime => nothing written;
#   * no config.toml yet => the v3 drop-in plus a warning;
#   * `containerd` => `nvidia-ctk runtime configure` then a containerd restart;
#   * no nvidia-container-runtime => only the can_run probe, for rke2, k3s
#     and containerd;
#   * 'bogus' (and 'none') => dies naming the valid runtimes before any host
#     command, not even the can_run probe, with and without the runtime
#     (karr #66; it used to pass quietly without the runtime).
#
# NOT covered -- a green prove is NOT evidence that containerd picks the
# runtime up: whether RKE2/K3s render the tmpl / import the drop-in, whether
# `nvidia-ctk runtime configure` edits the real /etc/containerd/config.toml,
# whether the restart bounces workloads. The config.toml contents below are
# hand-written stand-ins, not captures. A maintainer confirms on a real node:
# configure_containerd, restart rke2-agent/k3s-agent, then
# `grep -A3 nvidia /var/lib/rancher/rke2/agent/etc/containerd/config.toml`
# and run a pod with runtimeClassName: nvidia.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile mutating_lines );
use Rex::GPU::NVIDIA;

my $CLOBBER = qq{imports = ["/etc/containerd/conf.d/*.toml"]\nversion = 2};

my %CONFIG = (
  v2 => qq{version = 2\n\n[plugins."io.containerd.grpc.v1.cri"]\n}
    .qq{  sandbox_image = "index.docker.io/rancher/mirrored-pause:3.6"},
  v3 => qq{version = 3\nroot = "/var/lib/rancher/rke2/agent/containerd"\n\n}
    .qq{[plugins.'io.containerd.cri.v1.images']\n  snapshotter = "overlayfs"},
  # no version line: only the import of the v3 drop-in dir marks it v3
  'v3-imports' => qq{imports = ["/var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d/*.toml"]},
  present => qq{version = 3\n\n}
    .qq{[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia']\n}
    .qq{  runtime_type = "io.containerd.runc.v2"}
);

sub base_of { my ( $rt ) = @_; "/var/lib/rancher/$rt/agent/etc/containerd" }

# $tmpl / $config: file content, or undef for "no such file" (cat exits 1).
sub containerd_host {
  my ( %a ) = @_;
  my $base = base_of($a{runtime});
  my $cat = sub { defined $_[0] ? [ $_[0], 0 ] : [ '', 1 ] };
  return host_profile('debian-12',
    can_run   => { 'nvidia-container-runtime' => $a{no_runtime} ? 0 : 1 },
    responses => [
      [ "cat $base/config.toml.tmpl 2>/dev/null" => @{ $cat->($a{tmpl}) } ],
      [ "cat $base/config.toml 2>/dev/null"      => @{ $cat->($a{config}) } ],
      [ "test -f $base/config-v3.toml.tmpl"      => '', 1 ],
      [ "test -d $base/config-v3.toml.d"         => '', 1 ]
    ]);
}

sub configure {
  my ( $host, $runtime ) = @_;
  return record_host(host => $host, code => sub { Rex::GPU::NVIDIA::configure_containerd($runtime) });
}

sub warns { my ( $rec ) = @_; grep { $_->[0] eq 'warn' } @{ $rec->{logs} } }

# Golden.pm's read-only list knows `test -s`; the `test -f` / `test -d`
# probes of _path_exists are read-only too.
sub changes { grep { !/^run: test -[fd] \S+$/ } mutating_lines(@_) }

for my $rt (qw( rke2 k3s )) {
  my $base = base_of($rt);

  subtest "$rt: clobber tmpl => rm -f + v3 drop-in" => sub {
    my $rec = configure(containerd_host(runtime => $rt, tmpl => $CLOBBER, config => $CONFIG{present}), $rt);
    is($rec->{error}, undef, 'no die');
    is_deeply([ changes(@{ $rec->{lines} }) ], [
      "run: rm -f $base/config.toml.tmpl",
      "file: $base/config-v3.toml.d ensure=directory",
      "file: $base/config-v3.toml.d/99-nvidia.toml",
      ( map { '  | '.$_ } split /\n/, Rex::GPU::NVIDIA::_nvidia_containerd_dropin_v3() )
    ], 'removes exactly the clobber tmpl, then writes the drop-in');
    ok(!(grep { /config\.toml 2>/ } @{ $rec->{lines} }), 'config.toml is not read (its nvidia runtime is the clobber)');
    is(scalar(warns($rec)), 2, 'two warnings (removal, restart needed)');
    golden_is($rec, "containerd/$rt--clobber");
  };

  subtest "$rt: v2 config => base-extending tmpl" => sub {
    my $rec = configure(containerd_host(runtime => $rt, config => $CONFIG{v2}), $rt);
    is($rec->{error}, undef, 'no die');
    is_deeply([ grep { /^(?:file|run: rm)/ } @{ $rec->{lines} } ], [
      "file: $base ensure=directory",
      "file: $base/config.toml.tmpl"
    ], 'writes config.toml.tmpl, removes nothing');
    ok((grep { /^  \| \{\{ template "base" \. \}\}$/ } @{ $rec->{lines} }), 'the tmpl renders the base first');
    is(scalar(warns($rec)), 0, 'no warning');
    golden_is($rec, "containerd/$rt--v2");
  };

  for my $case (qw( v3 v3-imports )) {
    subtest "$rt: $case config => v3 drop-in" => sub {
      my $rec = configure(containerd_host(runtime => $rt, config => $CONFIG{$case}), $rt);
      is($rec->{error}, undef, 'no die');
      is_deeply([ grep { /^(?:file|run: rm)/ } @{ $rec->{lines} } ], [
        "file: $base/config-v3.toml.d ensure=directory",
        "file: $base/config-v3.toml.d/99-nvidia.toml"
      ], 'writes the drop-in only');
      is(scalar(warns($rec)), 0, 'no warning');
      golden_is($rec, "containerd/$rt--$case");
    };
  }

  subtest "$rt: nvidia already wired => writes nothing" => sub {
    my $rec = configure(containerd_host(runtime => $rt, config => $CONFIG{present}), $rt);
    is($rec->{error}, undef, 'no die');
    is_deeply([ changes(@{ $rec->{lines} }) ], [], 'no mutating command');
    is_deeply([ grep { /^file/ } @{ $rec->{lines} } ], [], 'no file written');
    golden_is($rec, "containerd/$rt--present");
  };

  subtest "$rt: no config.toml yet => v3 drop-in + warning" => sub {
    my $rec = configure(containerd_host(runtime => $rt), $rt);
    is($rec->{error}, undef, 'no die');
    is_deeply([ grep { /^file/ } @{ $rec->{lines} } ], [
      "file: $base/config-v3.toml.d ensure=directory",
      "file: $base/config-v3.toml.d/99-nvidia.toml"
    ], 'writes the drop-in');
    is(scalar(warns($rec)), 1, 'one warning');
    like((warns($rec))[0][1], qr/no generated \Q$base\E\/config\.toml yet/, '... about the missing config.toml');
    golden_is($rec, "containerd/$rt--fresh");
  };
}

subtest 'default runtime is rke2' => sub {
  my $rec = configure(containerd_host(runtime => 'rke2', config => $CONFIG{v2}), undef);
  my $want = configure(containerd_host(runtime => 'rke2', config => $CONFIG{v2}), 'rke2');
  is_deeply($rec->{lines}, $want->{lines}, 'configure_containerd() == configure_containerd("rke2")');
};

subtest 'containerd: nvidia-ctk runtime configure, then restart' => sub {
  my $rec = configure(containerd_host(runtime => 'rke2'), 'containerd');
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    'can_run: nvidia-container-runtime',
    'run: nvidia-ctk runtime configure --runtime=containerd 2>&1',
    'run: systemctl restart containerd 2>/dev/null'
  ], 'configure, then restart; nothing under /var/lib/rancher');
  golden_is($rec, 'containerd/containerd');
};

subtest 'no nvidia-container-runtime => only the probe, for every valid runtime name' => sub {
  for my $rt (qw( rke2 k3s containerd )) {
    my $rec = configure(containerd_host(runtime => 'rke2', no_runtime => 1), $rt);
    is($rec->{error}, undef, "$rt: no die");
    is_deeply($rec->{lines}, [ 'can_run: nvidia-container-runtime' ], "$rt: only can_run");
  }
};

subtest "unknown runtime dies before any host command, with and without the runtime" => sub {
  for my $no_runtime (0, 1) {
    my $with = $no_runtime ? 'without' : 'with';
    for my $rt (qw( bogus none )) {
      my $rec = configure(containerd_host(runtime => 'rke2', no_runtime => $no_runtime), $rt);
      is($rec->{error}, "Unknown containerd runtime: $rt (valid: rke2, k3s, containerd)",
        "$rt, $with runtime: dies naming the runtime and the valid ones");
      is_deeply($rec->{lines}, [], "$rt, $with runtime: no host command, not even the probe");
    }
  }
  golden_is(configure(containerd_host(runtime => 'rke2'), 'bogus'), 'containerd/bogus');
};

done_testing;
