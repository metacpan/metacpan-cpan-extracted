#!/usr/bin/env perl

use strict;
use warnings;
use POE;
use POE::Component::Client::DNS;
use POE::Session::YieldCC;

### Example code below here

sub _start {
  # pretend we just received a connection
  $_[KERNEL]->yield('conn_start');

  $_[HEAP]{dns} = POE::Component::Client::DNS->spawn();
}

# POE state handler invoked when a connection starts
sub conn_start {
  my $session = $_[SESSION];

  print "we've got a new connection!\n";

  # resolve the hostname for this connection's IP address (THE MAGIC)
  my $hostname = $session->yieldCC('fetch_hostname', "128.232.250.123");

  print "the remote hostname is: $hostname\n";
}

# resolve a hostname -- in the real world there is a PoCoCl::DNS here
sub fetch_hostname {
  my ($cont, $args) = @_[ARG0, ARG1];
  # $cont looks just like a postback!

  print "... fetching hostname for $$args[0] ...\n";

  my $rv = $_[HEAP]{dns}->resolve(
    type => 'PTR',
    host => join('.', reverse split /\./, $$args[0]) . ".in-addr.arpa",
    context => $cont,
    event => 'dns_response',
  );

  $_[KERNEL]->yield(dns_reponse => $rv)
    if defined $rv;
}

sub dns_response {
  my $response = $_[ARG0];
  print "... got hostname! ...\n";

  my @answer = $response->{response}->answer;
  my $hostname = $answer[0]->ptrdname;

  $response->{context}->( $hostname );

  print "WE *DO* GET HERE\n";
}

POE::Session::YieldCC->create(
  inline_states => {
    _start => \&_start,
    conn_start => \&conn_start,
    fetch_hostname => \&fetch_hostname,
    dns_response => \&dns_response,
  },
);

$poe_kernel->run();
