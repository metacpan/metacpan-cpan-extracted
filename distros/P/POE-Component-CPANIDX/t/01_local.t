use strict;
use warnings;
use Test::More tests => 6;
use POE qw(Component::CPANIDX Filter::HTTP::Parser);
use Test::POE::Server::TCP;
use HTTP::Date qw( time2str );
use HTTP::Response;

my $idx = POE::Component::CPANIDX->spawn();

POE::Session->create(
   package_states => [
        main => [qw(_start _stop testd_registered testd_client_input _reply)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::HTTP::Parser->new( type => 'server' ),
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{url} = "http://127.0.0.1:$port/";
  return;
}

sub _stop {
  $idx->shutdown;
  pass('Everything has stopped');
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $idx->query_idx(
    event => '_reply',
    url   => $heap->{url},
    cmd   => 'mod',
    search => 'Module::Load',
  );
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $req) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($req->as_string);
  isa_ok($req, 'HTTP::Request');
  is( $req->uri->path, '/yaml/mod/Module::Load', 'Requested URL is correct' );
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->header('Content-Type', 'text/x-yaml; charset=utf-8');
  $resp->header('Date', time2str(time));
  $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
  $resp->header('Connection', 'close');
  $resp->content( <<EOF
---
-
  cpan_id: KANE
  dist_file: K/KA/KANE/Module-Load-0.16.tar.gz
  dist_name: Module-Load
  dist_vers: 0.16
  mod_name: Module::Load
  mod_vers: 0.16
EOF
  );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $heap->{testd}->send_to_client($id, $resp);
  return;
}

sub _reply {
  my ($heap,$hashref) = @_[HEAP,ARG0];
  use Data::Dumper;
  $Data::Dumper::Indent=1;
  diag(Dumper($hashref->{data}));
  is( ref $hashref->{data}, 'ARRAY', 'We got an ARRAY ref' );
  is( ref $hashref->{data}->[0], 'HASH', 'Which contains a HASH ref' );
  is( $hashref->{data}->[0]->{mod_name}, 'Module::Load', 'There is a mod name field' );
  $heap->{testd}->shutdown();
  delete $heap->{testd};
  return;
}
