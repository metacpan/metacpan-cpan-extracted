use strict;
use POE qw(Component::Client::DNS Component::Server::DNS);
use Net::DNS::RR;
use Test::More tests => 5;

my $server = POE::Component::Server::DNS->spawn( port => 0, no_clients => 1 );

my $resolver = POE::Component::Client::DNS->spawn(
  Alias   => 'named',
  Timeout => 3,
  Nameservers => [ '127.0.0.1' ],
);

# This is so hacky.

POE::Session->create(
  inline_states  => {
    _start   => \&setup,
    go	     => \&start_tests,
    _stop    => sub { }, # avoid assert problems
    response => \&got_response,
    handler  => \&dns_handler,
  }
);

POE::Kernel->run();
exit;

sub setup {
  $poe_kernel->post( $server->session_id() => add_handler => { label => 'test', match => '\.com$', event => 'handler' } );
  $poe_kernel->delay( 'go', 5 );
  undef;
}

sub start_tests {
  my $port = $server->sockport();
  $resolver->get_resolver()->port($port);
  $_[HEAP]->{requests} = 4;
  my $request = 1;

  # Default IN A.  Override timeout.
  $resolver->resolve(
    event   => "response",
    host    => "localhost",
    context => $request++,
    timeout => 30,
  );

  # Default IN A.  Not found in /etc/hosts.
  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => $request++,
    timeout => 30,
  );

  # IN PTR (not in .com, so will give REFUSED)
  $resolver->resolve(
    event   => "response",
    host    => "127.0.0.1",
    class   => "IN",
    type    => "PTR",
    context => $request++,
  );

  # Small timeout.
  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => $request++,
    timeout => 0.001,
  );
}

sub dns_handler {
  my ($qname,$qclass,$qtype,$callback) = @_[ARG0..ARG3];
  my ($rcode, @ans, @auth, @add);
  my ($ttl, $rdata) = (3600, "10.1.2.3");
  push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
  $rcode = "NOERROR";
  $callback->($rcode, \@ans, \@auth, \@add, { aa => 1 });
  undef;
}

sub got_response {
  my ($request, $response) = @_[ARG0, ARG1];
  ok($request->{context}, "got response $request->{context} for $request->{host}");
  if($request->{type} eq 'PTR') {
    is( $request->{response}->header->rcode(), "REFUSED", "Refused an unhandled request");
  }
  $poe_kernel->post( $server->session_id, 'shutdown' ) if $_[HEAP]->{requests}-- <= 1;
}
