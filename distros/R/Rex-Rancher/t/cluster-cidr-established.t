use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k67: install_server writes config.yaml anew on every run, and since 0.003 a
# changed config.yaml restarts a running rke2 at once (start_verb). A
# cluster_cidr other than the one the server was set up with gave a running
# cluster another cluster-cidr on the spot: pods keep their addresses, the
# node podCIDRs and Cilium's pool drift apart. The case from kubernetes-ocp:
# clusters from before its k182 run on the built-in 10.42.0.0/16 with no
# cluster-cidr in config.yaml at all, and a re-run with network.pod_cidr
# 10.0.0.0/8 would have switched them live.
#
# Now, rke2 and k3s alike, against a server already set up on the host (its
# service active, or server/token there): the cluster-cidr it was set up
# with -- config.yaml plus config.yaml.d/*.yaml, merged as the distributions
# merge them (k3s' pkg/configfilearg: sorted by name, .yaml/.yml, the last
# value wins, key+ appends to an earlier one), else the built-in
# 10.42.0.0/16 -- must be the one this run gives it (cluster_cidr, else what
# config.yaml gets, else the built-in), or install_server dies before it
# writes or installs anything. A server not set up yet is not checked.
#
# run and file are faked: this proves the decision, the commands and the
# messages. That a real rke2/k3s merges its files like this and that a live
# re-run is refused is only shown by a live run.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Distribution;
use YAML::PP;

my $D = 'Rex::Rancher::Distribution';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

my %DIST = (
  rke2 => { dir => '/etc/rancher/rke2', service => 'rke2-server', version => 'v1.30.4+rke2r1' },
  k3s  => { dir => '/etc/rancher/k3s',  service => 'k3s',         version => 'v1.30.4+k3s1' },
);

# %host: active (the server service), token (server/token there), files
# (path => content), unreadable (path => 1), version (running and installed).
my ( @log, @warn, %host, %written );

sub dir_of { ( my $d = $_[0] ) =~ s{/[^/]+\z}{}; return $d }

{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    my $files = $host{files} // {};
    if ( $cmd =~ /^systemctl is-active --quiet \S+\z/ ) { $? = ( $host{active} ? 0 : 3 ) << 8; return '' }
    return "active\n" if $cmd =~ /^systemctl is-active \S+\z/;
    return 'MainPID='.( $host{active} ? 42 : 0 )."\n" if $cmd =~ /^systemctl show -p MainPID /;
    return "exe version $host{version} (abc)\n" if $cmd =~ m{^/proc/42/exe --version};
    return( $host{active} ? "$1 version $host{version} (abc)\n" : '' ) if $cmd =~ /^(rke2|k3s) --version/;
    if ( $cmd =~ m{^curl -fsSL -o /dev/null } ) { $? = 6 << 8; return '' }
    if ( $cmd =~ m{^test -e '([^']+)'\z} ) {
      my $p = $1;
      $? = ( exists $files->{$p} || ( $host{token} && $p =~ m{/server/token\z} ) ) ? 0 : 1 << 8;
      return '';
    }
    if ( $cmd =~ m{^test -d '([^']+)'\z} ) {
      my $d = $1;
      $? = ( grep { dir_of($_) eq $d } keys %$files ) ? 0 : 1 << 8;
      return '';
    }
    if ( $cmd =~ m{^find '([^']+)' -mindepth 1 -maxdepth 1 ! -type d\z} ) {
      my $d = $1;
      $? = 1 << 8 if $host{unreadable}{$d};
      # Not sorted, on purpose: the merge order is the reader's job.
      return join '', map { "$_\n" } reverse sort grep { dir_of($_) eq $d } keys %$files;
    }
    if ( $cmd =~ m{^cat '([^']+)'\z} ) {
      if ( $host{unreadable}{$1} || !exists $files->{$1} ) { $? = 1 << 8; return '' }
      return $files->{$1};
    }
    return "/usr/local/bin/rke2\n" if $cmd =~ /^command -v rke2/;
    return "yes\n" if $cmd =~ /^test -f /;
    if ( $cmd =~ /^cat / ) { $? = 1 << 8; return '' }
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  # One sub for both: Rex::Exporter aliases the whole glob.
  my $file = sub { my ( $p, %o ) = @_; push @log, "file $p"; $written{$p} = $o{content} if exists $o{content} };
  *Rex::Commands::File::file  = $file;
  *Rex::Rancher::Server::file = $file;
  *Rex::Commands::File::get_tmp_file_name = sub { '/tmp/.rex.tmp' };
  *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };
}

sub reset_host { %host = @_; ( @log, @warn ) = (); %written = () }

# Anything install_server writes, installs or starts.
sub touched { grep { /^file |^install -m |^chown |get\.(?:rke2|k3s)\.io|^systemctl (?:enable|start|restart) / } @log }

sub server { my ( $dist, %o ) = @_; install_server( distribution => $dist, token => 't', %o ) }

sub written_cidr {
  my ( $file ) = @_;
  return unless defined $written{$file};
  return YAML::PP->new->load_string( $written{$file} )->{'cluster-cidr'};
}

for my $dist (qw( rke2 k3s )) {
  my ( $dir, $svc, $v ) = @{ $DIST{$dist} }{qw( dir service version )};
  my $cfg    = "$dir/config.yaml";
  my $dropin = "$dir/config.yaml.d/50-ocp-cluster-cidr.yaml";
  my %up     = ( active => 1, version => $v );

  subtest "$dist: config.yaml's cluster-cidr, the same cluster_cidr: installs as before" => sub {
    reset_host( %up, files => { $cfg => "token: t\ncluster-cidr: 172.20.0.0/16\n" } );
    ok( eval { server( $dist, cluster_cidr => '172.20.0.0/16' ); 1 }, 'no die' ) or diag $@;
    is( written_cidr($cfg), '172.20.0.0/16', 'config.yaml written with it' );
    ok( ( grep { /get\.\Q$dist\E\.io/ } @log ), 'installer ran' );
    ok( ( grep { $_ eq "cat '$cfg'" } @log ), 'config.yaml read over the exec channel' );
    is_deeply( [ grep { !/^Could not (?:resolve the version|tell when)/ } @warn ], [], 'no warning of its own' );
  };

  subtest "$dist: config.yaml's cluster-cidr, another cluster_cidr: dies, nothing touched" => sub {
    reset_host( %up, files => { $cfg => "token: t\ncluster-cidr: 172.20.0.0/16\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, 'dies' );
    is( $@, "Refusing to install $dist with cluster-cidr 10.0.0.0/8 (cluster_cidr): the $dist "
      . "server on this host was set up with 172.20.0.0/16 (from $cfg), and the cluster-cidr of "
      . "a running cluster cannot be changed. Pass cluster_cidr => '172.20.0.0/16'. config.yaml "
      . "is unchanged and nothing was installed.\n", 'message: both values, why, the way out' );
    is_deeply( [ touched() ], [], 'nothing written, installed or started' );
  };

  subtest "$dist: a config.yaml.d drop-in overrides config.yaml" => sub {
    my %files = ( $cfg => "token: t\n", $dropin => "cluster-cidr: 172.20.0.0/16\n" );
    reset_host( %up, files => \%files );
    ok( eval { server( $dist, cluster_cidr => '172.20.0.0/16' ); 1 }, "the drop-in's value: installs" )
      or diag $@;
    ok( ( grep { $_ eq "cat '$dropin'" } @log ), 'the drop-in was read' );

    reset_host( %up, files => { %files, $cfg => "token: t\ncluster-cidr: 10.42.0.0/16\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, "config.yaml's value: dies" );
    like( $@, qr/^Refusing to install \Q$dist\E with cluster-cidr 10\.42\.0\.0\/16 \(cluster_cidr\): the \Q$dist\E server on this host was set up with 172\.20\.0\.0\/16 \(from \Q$dropin\E\)/,
      'names the drop-in and its value' );
    is_deeply( [ touched() ], [], 'nothing touched' );
  };

  subtest "$dist: active, no cluster-cidr anywhere: the built-in 10.42.0.0/16" => sub {
    reset_host( %up, files => { $cfg => "token: t\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, '10.0.0.0/8: dies' );
    is( $@, "Refusing to install $dist with cluster-cidr 10.0.0.0/8 (cluster_cidr): the $dist "
      . "server on this host was set up with 10.42.0.0/16 ($dist\'s built-in default: no "
      . "cluster-cidr in $cfg or $dir/config.yaml.d), and the cluster-cidr of a running cluster "
      . "cannot be changed. Pass cluster_cidr => '10.42.0.0/16'. config.yaml is unchanged and "
      . "nothing was installed.\n", 'names 10.42.0.0/16 and 10.0.0.0/8' );
    is_deeply( [ touched() ], [], 'nothing touched' );

    reset_host( %up, files => { $cfg => "token: t\n" } );
    ok( eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, '10.42.0.0/16: installs' ) or diag $@;
    is( written_cidr($cfg), '10.42.0.0/16', 'and writes it' );

    reset_host(%up);
    ok( !eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, 'no config.yaml at all: dies the same' );
    like( $@, qr/set up with 10\.42\.0\.0\/16 \(\Q$dist\E's built-in default/, 'against the built-in' );
  };

  subtest "$dist: not active, server/token there: set up all the same" => sub {
    reset_host( token => 1, version => $v );
    ok( !eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, 'dies' );
    like( $@, qr/^Refusing to install \Q$dist\E with cluster-cidr 10\.0\.0\.0\/8 .*set up with 10\.42\.0\.0\/16/,
      'against the built-in' );
    ok( ( grep { $_ eq "test -e '/var/lib/rancher/$dist/server/token'" } @log ), 'asked for server/token' );
    is_deeply( [ touched() ], [], 'nothing touched' );

    reset_host( token => 1, version => $v );
    ok( eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'the same value: installs' ) or diag $@;
  };

  subtest "$dist: cluster_cidr left out against a custom value: dies" => sub {
    reset_host( %up, files => { $cfg => "token: t\ncluster-cidr: 172.20.0.0/16\n" } );
    ok( !eval { server($dist); 1 }, 'dies' );
    is( $@, "Refusing to install $dist with cluster-cidr 10.42.0.0/16 (cluster_cidr not given: "
      . "the default): the $dist server on this host was set up with 172.20.0.0/16 (from $cfg), "
      . "and the cluster-cidr of a running cluster cannot be changed. Pass cluster_cidr => "
      . "'172.20.0.0/16'. config.yaml is unchanged and nothing was installed.\n",
      'says the value compared is the default' );
    is_deeply( [ touched() ], [], 'nothing touched' );

    reset_host( %up, files => { $cfg => "token: t\n" } );
    ok( eval { server($dist); 1 }, 'left out against the built-in: installs' ) or diag $@;
  };

  subtest "$dist: not set up (not active, no server/token): not checked" => sub {
    reset_host( version => $v );
    ok( eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, 'installs' ) or diag $@;
    is( written_cidr($cfg), '10.0.0.0/8', 'config.yaml gets it' );
    ok( !( grep { /^cat '|^find |^test -d / } @log ), 'no config read' );

    # A config.yaml without server/token belongs to a server that never came
    # up (an aborted first run, a node whose /var/lib/rancher was wiped): its
    # cluster-cidr is set nowhere yet and may be corrected.
    reset_host( version => $v, files => { $cfg => "token: t\ncluster-cidr: 172.20.0.0/16\n" } );
    ok( eval { server( $dist, cluster_cidr => '10.0.0.0/8' ); 1 }, 'a leftover config.yaml: installs' )
      or diag $@;
    is( written_cidr($cfg), '10.0.0.0/8', 'with the new value' );
  };

  subtest "$dist: a file that cannot be read or parsed: dies with its name" => sub {
    my $secret = 'K10deadbeef::server:s3cr3t';
    reset_host( %up, files => { $cfg => "token: t: $secret\nnode-name: x\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'unparsable config.yaml: dies' );
    is( $@, "Could not parse $cfg as YAML (line 1), so the cluster-cidr the $dist server on this "
      . "host was set up with is unknown. config.yaml is unchanged and nothing was installed.\n",
      'names the file and the line' );
    unlike( $@, qr/s3cr3t/, 'and none of its content: it holds the token' );
    is_deeply( [ touched() ], [], 'nothing touched' );

    reset_host( %up, files => { $cfg => "token: t\n", $dropin => "x\n" }, unreadable => { $dropin => 1 } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'unreadable drop-in: dies' );
    like( $@, qr/^Could not read \Q$dropin\E \(cat exited 1\), so the cluster-cidr the \Q$dist\E server on this host was set up with is unknown\./,
      'names the drop-in' );
    is_deeply( [ touched() ], [], 'nothing touched' );

    reset_host( %up, files => { $dropin => "cluster-cidr: 10.42.0.0/16\n" },
      unreadable => { "$dir/config.yaml.d" => 1 } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'unlistable config.yaml.d: dies' );
    like( $@, qr/^Could not list \Q$dir\E\/config\.yaml\.d \(find exited 1\), so /, 'names the directory' );

    reset_host( %up, files => { $cfg => "- token\n- t\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'not a mapping: dies' );
    like( $@, qr/^\Q$cfg\E is not a YAML mapping, so /, 'names the file' );

    reset_host( %up, files => { $dropin => "cluster-cidr: { v4: 10.42.0.0/16 }\n" } );
    ok( !eval { server( $dist, cluster_cidr => '10.42.0.0/16' ); 1 }, 'cluster-cidr a mapping: dies' );
    like( $@, qr/^\Q$dropin\E: cluster-cidr is neither a string nor a list of strings, so /, 'names the file' );
  };
}

subtest 'established_cluster_cidr: the files merged as rke2 and k3s merge them' => sub {
  my $d   = $D->new_for('rke2');
  my $cfg = '/etc/rancher/rke2/config.yaml';
  my $dd  = '/etc/rancher/rke2/config.yaml.d';

  reset_host( active => 1, files => {
    $cfg               => "cluster-cidr: 10.1.0.0/16\n",
    "$dd/10-a.yaml"    => "cluster-cidr: 10.2.0.0/16\n",
    "$dd/50-b.yml"     => "cluster-cidr: 10.3.0.0/16\n",
    "$dd/20-c.YAML"    => "node-name: x\n",
    "$dd/90-d.yaml.bak" => "cluster-cidr: 10.9.0.0/16\n",
    "$dd/README"       => "cluster-cidr: 10.9.0.0/16\n",
  } );
  is_deeply( [ $d->established_cluster_cidr ], [ '10.3.0.0/16', "$dd/50-b.yml" ],
    'sorted by name, .yml counts, the last value wins, other names ignored' );
  is_deeply( [ grep { /^cat / } @log ],
    [ "cat '$cfg'", "cat '$dd/10-a.yaml'", "cat '$dd/20-c.YAML'", "cat '$dd/50-b.yml'" ],
    'config.yaml first, then the drop-ins in order' );

  reset_host( active => 1, files => { "$dd/50-b.yaml" => "cluster-cidr: 10.3.0.0/16\n" } );
  is_deeply( [ $d->established_cluster_cidr ], [ '10.3.0.0/16', "$dd/50-b.yaml" ], 'a drop-in without config.yaml' );

  reset_host( active => 1, files => { $cfg => "cluster-cidr:\n  - 10.1.0.0/16\n  - fd00::/56\n" } );
  is( scalar $d->established_cluster_cidr, '10.1.0.0/16,fd00::/56', 'a list: as one comma-separated value' );

  reset_host( active => 1, files => {
    $cfg            => "cluster-cidr: 10.1.0.0/16\n",
    "$dd/60-v6.yaml" => "cluster-cidr+: [fd00::/56]\n",
  } );
  is( scalar $d->established_cluster_cidr, '10.1.0.0/16,fd00::/56', 'cluster-cidr+ appends to an earlier value' );

  reset_host( active => 1, files => { "$dd/60-v6.yaml" => "cluster-cidr+: 10.5.0.0/16\n" } );
  is( scalar $d->established_cluster_cidr, '10.5.0.0/16', 'cluster-cidr+ with nothing earlier: that value alone' );

  reset_host( active => 1, files => { $cfg => "cluster-cidr+: [10.7.0.0/16]\ncluster-cidr: 10.1.0.0/16\n" } );
  is( scalar $d->established_cluster_cidr, '10.1.0.0/16', 'in the order of the file' );

  reset_host( active => 1, files => { $cfg => "cluster-cidr: 10.1.0.0/16\ncluster-cidr: 10.2.0.0/16\n" } );
  is( scalar $d->established_cluster_cidr, '10.2.0.0/16', 'a repeated key: the last, as rke2 reads it' );

  reset_host( active => 1, files => { $cfg => '' } );
  is_deeply( [ $d->established_cluster_cidr ], [ '10.42.0.0/16', undef ], 'empty config.yaml: the built-in' );

  reset_host();
  is_deeply( [ $d->established_cluster_cidr ], [], 'not set up: nothing' );
  is_deeply( \@log, [ "systemctl is-active --quiet rke2-server", "test -e '/var/lib/rancher/rke2/server/token'" ],
    'and nothing read but the service and server/token' );

  reset_host( files => { $cfg => "cluster-cidr: 10.1.0.0/16\n" } );
  ok( !$d->is_established, 'a config.yaml alone is not set up' );
};

subtest 'the built-in cluster-cidr' => sub {
  is( $D->new_for($_)->builtin_cluster_cidr, '10.42.0.0/16', "$_: 10.42.0.0/16" ) for qw( rke2 k3s );
  is( $D->new_for('rke2')->default_cluster_cidr, undef, 'rke2 still writes none by default' );
  is( $D->new_for('k3s')->default_cluster_cidr, '10.42.0.0/16', 'k3s still writes it with cilium' );
};

subtest 'the value compared is the one config.yaml gets, else the built-in' => sub {
  for my $dist (qw( rke2 k3s )) {
    my $d = $D->new_for($dist);
    for my $cilium ( 1, 0 ) {
      for my $given ( undef, '172.20.0.0/16' ) {
        my $name = "$dist, cilium $cilium, cluster_cidr " . ( $given // 'not given' );
        my $expect = Rex::Rancher::Server::_build_server_config( $d, 't', undef, undef, undef, $cilium,
          undef, undef, $given )->{'cluster-cidr'} // '10.42.0.0/16';
        reset_host( active => 1, files => { $d->config_file => "cluster-cidr: 192.168.0.0/16\n" } );
        ok( !eval { $d->check_established_cluster_cidr( cluster_cidr => $given, cilium => $cilium ); 1 },
          "$name: dies against 192.168.0.0/16" );
        like( $@, qr/^Refusing to install \Q$dist\E with cluster-cidr \Q$expect\E /, "$name: compares $expect" );
      }
    }
  }
  reset_host( active => 1, files => { '/etc/rancher/k3s/config.yaml' => "cluster-cidr: ' 10.42.0.0/16 '\n" } );
  is( $D->new_for('k3s')->check_established_cluster_cidr( cluster_cidr => '10.42.0.0/16', cilium => 1 ),
    '10.42.0.0/16', 'compared trimmed' );
};

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
