# $Id: XMLRPC.pm,v 1.4 2003/03/20 23:26:02 mah Exp $
# License and documentation are after __END__.

package POE::Component::Server::XMLRPC;

use warnings;
use strict;
use Carp qw(croak);

use vars qw($VERSION);
$VERSION = '0.05';

use POE;
use POE::Component::Server::HTTP;
use XMLRPC::Lite;

my %public_interfaces;

sub new {
  my $type = shift;

  croak "Must specify an even number of parameters to $type\->new()" if @_ % 2;
  my %params = @_;

  my $alias = delete $params{alias};
  croak "Must specify an alias in $type\->new()"
    unless defined $alias and length $alias;

  my $interface = delete $params{interface};
  croak "$type\->new() currently does not support the interface parameter"
    if defined $interface;

  my $port = delete $params{port};
  $port = 80 unless $port;

  POE::Session->create
    ( inline_states =>
      { _start => sub {
          $_[KERNEL]->alias_set($alias);
        },
        publish => sub {
          my ($alias, $event) = @_[ARG0, ARG1];
          $public_interfaces{$alias}{$event} = 1;
        },
        rescind => sub {
          my ($alias, $event) = @_[ARG0, ARG1];
          delete $public_interfaces{$alias}{$event};
        },
      }
    );

  POE::Component::Server::HTTP->new
    ( Port     => $port,
      Headers  =>
      { Server => "POE::Component::Server::XMLRPC/$VERSION",
      },
      ContentHandler => { "/" => \&web_handler },
    );

  undef;
}

### Handle web requests by farming them out to other sessions.

sub web_handler {
  my ($request, $response) = @_;

  # Parse useful things from the request.

  my $query_string = $request->uri->query();
  unless (defined($query_string) and $query_string =~ /\bsession=(.+ $ )/x) {
    $response->code(400);
    return RC_OK;
  }
  my $session = $1;

  my $http_method            = $request->method();
  my $request_content_type   = $request->header('Content-Type');
  my $request_content_length = $request->header('Content-Length');
  my $debug_request          = $request->header('DebugRequest');
  my $request_content        = $request->content();
  my $data                   = XMLRPC::Deserializer
    ->deserialize($request_content);
  my $method_name            = $data->valueof("methodName");
  my $args                   = $data->valueof("params");

  unless ($request_content_type =~ /^text\/xml(;.*)?$/) {
    _request_failed( $response,
		     403,
                     "Bad Request",
                     "Content-Type must be text/xml.",
                   );
    return RC_OK;
  }

  unless (defined($method_name) and length($method_name)) {
    _request_failed( $response,
                     403,
                     "Bad Request",
                     "methodName is required.",
                   );
    return RC_OK;
  }

  unless ($method_name =~ /^(\S+)$/) {
   _request_failed( $response,
		    403,
                    "Bad Request",
                    "Unrecognized methodName: $method_name",
                  );
  }

  unless (exists $public_interfaces{$session}) {
    _request_failed( $response,
		     500,
                     "Bad Request",
                     "Unknown session: $session",
                   );
    return RC_OK;
  }

  unless (exists $public_interfaces{$session}{$method_name}) {
    _request_failed( $response,
		     500,
                     "Bad Request",
                     "Unknown method: $method_name",
                   );
    return RC_OK;
  }

  eval {
    XMLRPCTransaction->start($response, $session, $method_name, $args);
  };

  if ($@) {
    _request_failed( $response,
                     500,
                     "Application Faulted",
                     "An exception fired while processing the request: $@",
                   );
  }

  return RC_WAIT;
}

sub _request_failed {
  my ($response, $fault_code, $fault_string, $result_description) = @_;

  my $response_content = qq{<?xml version="1.0"?>
<methodResponse>
<fault><value><struct>
<member><name>faultCode</name><value><int>$fault_code</int></value></member>
<member><name>faultString</name><value><string>$fault_string</string></value>
</member>
</struct></value></fault>
</methodResponse>};

  $response->code(200);
  $response->header("Content-Type", "text/xml");
  $response->header("Content-Length", length($response_content));
  $response->content($response_content);
}

package XMLRPCTransaction;

sub TR_RESPONSE () { 0 }
sub TR_SESSION  () { 1 }
sub TR_EVENT    () { 2 }
sub TR_ARGS     () { 3 }

sub start {
  my ($type, $response, $session, $event, $args) = @_;

  my $self = bless
    [ $response,
      $session,
      $event,
      $args,
    ], $type;

  $POE::Kernel::poe_kernel->post($session, $event, $self);
  undef;
}

sub params {
  my $self = shift;
  return $self->[TR_ARGS];
}

sub return {
  my ($self, $retval) = @_;

  my $content = XMLRPC::Serializer->envelope(response => 'toMethod', $retval);
  my $response = $self->[TR_RESPONSE];

  $response->code(200);
  $response->header("Content-Type", "text/xml");
  $response->header("Content-Length", length($content));
  $response->content($content);
  $response->continue();
}

1;

__END__

=head1 NAME

POE::Component::Server::XMLRPC - publish POE event handlers via XMLRPC over HTTP

=head1 SYNOPSIS

  use POE;
  use POE::Component::Server::XMLRPC;

  POE::Component::Server::XMLRPC->new( alias => "xmlrpc", port  => 32080 );

  POE::Session->create
    ( inline_states =>
      { _start => \&setup_service,
        _stop  => \&shutdown_service,
        sum_things => \&do_sum,
      }
    );

  $poe_kernel->run;
  exit 0;

  sub setup_service {
    my $kernel = $_[KERNEL];
    $kernel->alias_set("service");
    $kernel->post( xmlrpc => publish => service => "sum_things" );
  }

  sub shutdown_service {
    $_[KERNEL]->post( xmlrpc => rescind => service => "sum_things" );
  }

  sub do_sum {
    my $transaction = $_[ARG0];
    my $params = $transaction->params();
    my $sum = 0;
    for(@{$params}) {
      $sum += $_;
    }
    $transaction->return("Thanks.  Sum is: $sum");
  }

=head1 DESCRIPTION

POE::Component::Server::XMLRPC is a bolt-on component that can publish a
event handlers via XMLRPC over HTTP.

There are four steps to enabling your programs to support XMLRPC
requests.  First you must load the component.  Then you must
instantiate it.  Each POE::Component::Server::XMLRPC instance requires
an alias to accept messages with and a port to bind itself to.
Finally, your program should posts a "publish" events to the server
for each event handler it wishes to expose.

  use POE::Component::Server::XMLRPC
  POE::Component::Server::XMLRPC->new( alias => "xmlrpc", port  => 32080 );
  $kernel->post( xmlrpc => publish => session_alias => "methodName" );

Later you can make events private again.

  $kernel->post( xmlrpc => rescind => session_alias => "methodName" );

Finally you must write the XMLRPC request handler.  XMLRPC
handlers receive a single parameter, ARG0, which contains a
XMLRPC transaction object.  The object has two methods: params(),
which returns a reference to the XMLRPC parameters; and return(),
which returns its parameters to the client as a XMLRPC response.

  sum_things => sub {
    my $transaction = $_[ARG0];
    my $params = $transaction->params();
    my $sum = 0;
    while (@{$params})
      $sum += $value;
    }
    $transaction->return("Thanks.  Sum is: $sum");
  }

And here is a sample XMLRPC::Lite client.  It should work with the
server in the SYNOPSIS.

  #!/usr/bin/perl

  use warnings;
  use strict;

  use XMLRPC::Lite;

  print XMLRPC::Lite
    -> proxy('http://poe.dynodns.net:32080/?session=sum_server')
    -> sum_things(8,6,7,5,3,0,9)
    -> result
    ;
  pring "\n";

=head1 BUGS

This project is a modified version of
POE::Component::Server::SOAP by Rocco Caputo.  Of that, he
writes:

  This project was created over the course of two days, which attests to
  the ease of writing new POE components.  However, I did not learn XMLRPC
  in depth, so I am probably not doing things the best they could.

Thanks to his code, I've managed to create this module in one day
(on only my second day of using POE).  There's gotta be bugs
here.  Please use http://rt.cpan.org/ to report them.

=head1 SEE ALSO

The examples directory that came with this component.

XMLRPC::Lite
POE::Component::Server::SOAP
POE::Component::Server::HTTP
POE

=head1 AUTHOR & COPYRIGHTS

POE::Component::Server::XMLRPC is Copyright 2002 by 
Mark A. Hershberger.  All rights are reserved.
POE::Component::Server::XMLRPC is free software; you may
redistribute it and/or modify it under the same terms as Perl
itself.

=cut
