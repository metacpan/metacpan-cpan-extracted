package Net::DNSServer::Base;

use strict;
use Carp qw(croak);

# Created before calling Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self = shift || {};
  return bless $self, $class;
}

# Called once at configuration load time by Net::DNSServer.
# Takes the Net::Server object as an argument.
sub init {
  my $self = shift;
  my $net_server = shift;
  unless ($net_server && (ref $net_server) && ($net_server->isa("Net::Server"))) {
    croak 'Usage> '.(__PACKAGE__).'->init($Net_Server_obj)';
  }
  $self -> {net_server} = $net_server,
  return 1;
}

# Called immediately after incoming request
# Takes the Net::DNS::Packet question as an argument
sub pre {
  my $self = shift;
  my $net_dns_packet = shift || croak 'Usage> $obj->resolve($Net_DNS_obj)';
  $self -> {question} = $net_dns_packet;
  return 1;
}

# Called after all pre methods have finished
# Returns a Net::DNS::Packet object as the answer
#   or undef to pass to the next module to resolve
sub resolve {
  die "virtual function not implemented";
}

# Called after resolve.
# Takes the Net::DNS::Packet question as an argument.
# If may modify $self->{answer_packet} before
# it is sent to the client.
sub post {
  my $self = shift;
#  my $net_dns_packet = shift || croak 'Usage> $obj->post($Net_DNS_obj)';
  return 1;
}

# Called once prior to server shutdown
sub cleanup {
  return 1;
}

1;

__END__

=head1 NAME

Net::DNSServer::Base - This is meant to be the base class for all resolving module handlers.

=head1 SYNOPSIS

Example Usage:

  #!/usr/bin/perl -w -T
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::Cache;
  use MyTestResolver;
  my $resolver1 = new Net::DNSServer::Cache;
  my $resolver2 = new MyTestResolver {dom => "test.com"};
  run Net::DNSServer {
    priority => [$resolver1,$resolver2],
  };  # Never returns

Example MyTestResolver.pm Contents:

  package MyTestResolver;
  use strict;
  use Exporter;
  use Net::DNSServer::Base;
  use Net::DNS::Packet;
  use vars qw(@ISA);
  @ISA = qw(Net::DNSServer::Base);

  # resolve subroutine must be defined
  sub resolve {
    my $self = shift;
    my $dns_packet = $self -> {question};
    my ($question) = $dns_packet -> question();
    if ($question -> qname eq $self->{dom} &&
        $question -> qtype eq "A") {
      my $response = bless \%{$dns_packet}, "Net::DNS::Packet"
        || die "Could not initialize response packet";
      $response->push("answer",
                      [Net::DNS::RR->new
                       ("$self->{dom} 1000 A 127.0.0.100")]);
      $response->push("authority",
                      [Net::DNS::RR->new
                       ("$self->{dom} 1000 NS ns1.$self->{dom}")]);
      $response->push("additional",
                      [Net::DNS::RR->new
                       ("ns1.$self->{dom} 1000 A 127.0.0.200")]);
      my $response_header = $response->header;
      $response_header->aa(1); # Make Authoritative
      return $response;
    }
    return undef;
  }


=head1 DESCRIPTION

The main invoker program should call the new() method
for each resolver to create an instance of each.  Each
resolver ISA Net::DNSServer::Base which must explicitly
define a resolve() method.  A reference to a list of
these objects is passed to run() as the "priority"
argument as demonstrated in the SYNOPSIS above.
Net::DNSServer->run() never returns.


=head1 METHODS

There are a few methods that each resolver may define.

=head2 new

Input -
It may take anything it needs pertaining
to whatever its purpose is.

Output -
It must return an instance of its resolver
(i.e., blessed with itself).

Purpose -
Called by the main invoker program to create
the resolver object.  The result is meant to
be passed to the run() method of Net::DNSServer.

Default -
Just blesses the first argument with its class.
If no argument is passed, it uses an empty hash ref.

=head2 init

Input -
It takes the Net::Server or Net::DNSServer
object as input.

Output -
Ignored.

Purpose -
At configuration time, Net::DNSServer will
call init() exactly once for each resolver.
It is gaurenteed to occur before any forking,
so all constant data loaded at this time
should remain within shared memory if the
name server were ever to fork.

Default -
Stores the Net::Server argument into its
"net_server" property.

=head2 pre

Input -
It takes the entire Net::DNS::Packet object
that the client asked as its argument.

Output -
Ignored.

Purpose -
The pre() method is called for each resolver
in the order in which they were passed to the
"priority" array ref every time an incoming
request is received.

Default -
Stores the Net::DNS::Packet argument into its
"question" property.

=head2 resolve

Input -
None, it must use what was passed from the pre() method

Output -
It must return a Net::DNS::Packet object to be
sent back to the client as the response.  To pass
control to the next resolver, it must return undef.

Purpose -
The resolve() method is called for each
resolver in the order in which they were
passed to the "priority" array ref until
one returns a Net::DNS::Packet object.

Default -
No default; this is a virtual function.
Each resolver must define this method.

=head2 post

Input -
The response Net::DNS::Packet object.

Output -
Ignored.

Purpose -
After the resolve() method(s) are called, the
post() method is called for each resolver in
the order in which they were passed to the
"priority" array ref.
It is useful for caching resolvers or for
fixing up the response packet before sending
it to the client.

Default -
Do nothing.

=head2 cleanup

Input -
None.

Output -
Ignored.

Purpose -
At shutdown or restart, Net::DNSServer will
call cleanup() exactly once for each resolver.
It is meant to cleanup any resources it may
have caused to the system.

Default -
Do nothing.

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<Net::DNSServer>,
L<Net::DNSServer::Cache>,
L<Net::DNSServer::SharedCache>,
L<Net::DNSServer::DBMCache>,
L<Net::DNSServer::Proxy>,
L<Net::DNS::Packet>

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: Base.pm,v 1.13 2002/04/08 06:58:54 rob Exp $

=cut
