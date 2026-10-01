use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k74: update_registries restarts the service so it reads the new
# registries.yaml. On a node that never went through install_server or
# install_agent again after Rex::GPU 0.001, that restart renders the bare
# config.toml.tmpl (only imports and version = 2) again, and the new mirrors
# never reach containerd. So update_registries removes that template before
# the restart (remove_bare_containerd_template, as the install paths do since
# k72), for rke2 and k3s alike: decided by content, any other template stays,
# no template is a no-op, and a failed removal dies before the restart.
#
# run and file are faked: this proves the commands and their order, not that
# a real rke2 or k3s renders its own config with the mirrors afterwards.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Distribution;

my $D = 'Rex::Rancher::Distribution';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# What Rex::GPU 0.001 (and kubernetes-ocp before its k23) wrote.
my $BARE    = qq{imports = ["/etc/containerd/conf.d/*.toml"]\nversion = 2\n};
my $FOREIGN = <<'TMPL';
{{ template "base" . }}

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.custom]
  runtime_type = "io.containerd.runc.v2"
TMPL

my $REG = { mirrors => { 'docker.io' => { endpoint => ['http://cache:5000'] } } };

# Fake host: %files maps path => content, $rm_fails makes `rm` fail. @log
# records every command and file write.
my ( %files, @log, @info, @warn, $rm_fails );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    if ( $cmd =~ m{^cat (\S+) 2>/dev/null$} ) {
      return $files{$1} if exists $files{$1};
      $? = 1 << 8;
      return '';
    }
    if ( $cmd =~ m{^rm -f (\S+)} ) {
      if ($rm_fails) {
        $? = 1 << 8;
        return "rm: cannot remove '$1': Operation not permitted\n";
      }
      delete $files{$1};
      return '';
    }
    return '';
  };
  my $file = sub { push @log, 'file '.$_[0] };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Commands::File::file  = $file;
  *Rex::Rancher::Server::file = $file;
  *Rex::Logger::info = sub { push @{ ( $_[1] // '' ) eq 'warn' ? \@warn : \@info }, $_[0] };
}

sub reset_host {
  my ( %args ) = @_;
  %files    = %{ $args{files} // {} };
  $rm_fails = $args{rm_fails};
  ( @log, @info, @warn ) = ();
}

sub index_of { my ( $re ) = @_; my $i = 0; for (@log) { return $i if $_ =~ $re; $i++ } return }

for my $dist (qw( rke2 k3s )) {
  my $d        = $D->new_for($dist);
  my $tmpl     = $d->containerd_dir.'/config.toml.tmpl';
  my $restart  = $d->restart_services_cmd;
  my $reg_file = $d->registries_file;
  my $restart_i = sub { index_of(qr{^\Q$restart\E$}) };

  is( $tmpl, "/var/lib/rancher/$dist/agent/etc/containerd/config.toml.tmpl",
    $dist.': the template update_registries looks at' );

  subtest $dist.': bare template: removed before the restart' => sub {
    reset_host( files => { $tmpl => $BARE } );
    update_registries( distribution => $dist, registries => $REG );

    ok( !exists $files{$tmpl}, 'template removed' );
    my $rm    = index_of(qr{^rm -f \Q$tmpl\E\b});
    my $cat   = index_of(qr{^cat \Q$tmpl\E 2>/dev/null$});
    my $write = index_of(qr{^file \Q$reg_file\E$});
    my $rs    = $restart_i->();
    ok( defined $rm, 'rm -f over the exec channel' );
    ok( defined $cat && defined $rm && $cat < $rm, 'read with cat first' );
    ok( defined $write, 'registries.yaml written' );
    ok( defined $rs, 'the service restarted' );
    ok( defined $rm && defined $rs && $rm < $rs, 'removed before the restart' );
    my @removed = grep { /Removing \Q$tmpl\E/ } @warn;
    is( scalar @removed, 1, 'the removal is logged as a warning' );
  };

  subtest $dist.': foreign template: kept, with a note, restart as before' => sub {
    reset_host( files => { $tmpl => $FOREIGN } );
    update_registries( distribution => $dist, registries => $REG );

    is( $files{$tmpl}, $FOREIGN, 'untouched' );
    ok( !( grep { /^rm / } @log ), 'no rm' );
    ok( ( grep { /Keeping \Q$tmpl\E/ } @info ), 'a note in the log' );
    ok( !( grep { /\Q$tmpl\E/ } @warn ), 'no warning about it' );
    ok( defined $restart_i->(), 'the service restarted' );
  };

  subtest $dist.': no template: only a cat, restart as before' => sub {
    reset_host();
    update_registries( distribution => $dist, registries => $REG );

    ok( !( grep { /^rm / } @log ), 'no rm' );
    is( scalar( grep { /config\.toml\.tmpl/ } @log ), 1, 'the one cat' );
    ok( !( grep { /config\.toml\.tmpl/ } @info, @warn ), 'nothing logged about it' );
    ok( defined $restart_i->(), 'the service restarted' );
  };

  subtest $dist.': rm fails: dies loudly, nothing restarted' => sub {
    reset_host( rm_fails => 1, files => { $tmpl => $BARE } );
    ok( !eval { update_registries( distribution => $dist, registries => $REG ); 1 }, 'dies' );
    like( $@, qr/Could not remove \Q$tmpl\E/, 'names the file' );
    like( $@, qr/Operation not permitted/, 'carries rm\'s error' );
    ok( defined index_of(qr{^file \Q$reg_file\E$}), 'registries.yaml was written before' );
    ok( !defined $restart_i->(), 'no restart' );
    ok( !( grep { /^systemctl / } @log ), 'no systemctl at all' );
  };
}

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
