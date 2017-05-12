package POE::Component::FastCGI;
BEGIN {
  $POE::Component::FastCGI::VERSION = '0.19';
}

use strict;

use Carp qw(croak);
use Socket qw(AF_UNIX);

use POE qw(
   Component::Server::TCP
   Wheel::ReadWrite
   Driver::SysRW
   Filter::FastCGI);

use POE::Component::FastCGI::Request;
use POE::Component::FastCGI::Response;

sub new {
   my($class, %args) = @_;

   croak "No port or address to listen on configured"
      unless defined $args{Port} or (defined $args{Unix} and defined
      $args{Address});
   croak "No handlers defined" unless defined $args{Auth} or defined
      $args{Handlers};

   my $session_id = POE::Session->create(
      inline_states => {
         _start => \&_start,
         accept => \&_accept,
         input  => \&_input,
         error  => \&_error,
         client_shutdown  => \&_client_shutdown,

         # For graceful external shutdown
         shutdown => \&_shutdown,

         # triggered from PoCo::FastCGI::Response in order to make sure
         # we're writing to our wheel from the correct session.
         w_send => \&_w_send,
         w_write => \&_w_write,
         w_close => \&_w_close,

         # Dummys to keep of warnings
         _stop => sub {},
         _child => sub {}
      },
      heap => \%args,
   )->ID;

   return $session_id;
}

sub _start {
   my($session, $heap) = @_[SESSION, HEAP];

   $heap->{server} = POE::Component::Server::TCP->new(
      Port => $heap->{Port},
      (defined $heap->{Unix} ? (Domain => AF_UNIX) : ()),
      (defined $heap->{Address} ? (Address => $heap->{Address}) : ()),
      Acceptor => sub {
         $poe_kernel->post($session => accept => @_[ARG0, ARG1, ARG2]);
      }
   );
}

sub _accept {
   my($heap, $socket, $remote_addr, $remote_port) = @_[HEAP, ARG0, ARG1, ARG2];

   # XXX: check fastcgi is allowed to connect.

   my $wheel = POE::Wheel::ReadWrite->new(
      Handle => $socket,
      Driver => POE::Driver::SysRW->new(),
      Filter => POE::Filter::FastCGI->new(),
      InputEvent => 'input',
      ErrorEvent => 'error'
   );
   $heap->{wheels}->{$wheel->ID} = $wheel;
}

sub _input {
   my($heap, $session, $kernel, $fcgi, $wheel_id) = @_[HEAP, SESSION, KERNEL, ARG0, ARG1];

   my $client = $heap->{wheels}->{$wheel_id};

   my $request = POE::Component::FastCGI::Request->new(
      $client, $session->ID,
      $fcgi->[0], # request id
      $fcgi->[2], # cgi parameters
      $fcgi->[1]->{postdata}
   );

   if($fcgi->[1]->{role} eq 'AUTHORIZER') {
      if(defined $heap->{Auth}) {
         $heap->{Auth}->($request);
      }else{
         $request->error(500, "FastCGI authorizer role requested but not configured");
      }
      return;
   }

   my $path = $request->uri->path;

   my $run;

   for my $handler(@{$heap->{Handlers}}) {
      if(ref $handler->[0] eq 'Regexp') {
         $run = $handler, last if $path =~ /$handler->[0]/;
      }else{
         $run = $handler, last if
            (($handler->[0] !~ m!/! and $path =~ m!^/$handler->[0]($|/)!) or
            ($handler->[0] eq $path));
      }
   }

   if(not defined $run) {
      $request->error(404, "No handler found for $path");
   }else{

     if(ref($run->[1]) eq 'CODE' or $run->[1]->isa('POE::Session::AnonEvent') ) {
       $run->[1]->($request, $run->[0]);
     } else {
       $kernel->post($heap->{Session}, $run->[1],$request, $run->[0]);
     }

	 if($request->{_res}) {
		 # Streaming support
		 if($request->{_res}->streaming) {
			 push @{$heap->{toclose}->{$wheel_id}}, $request->{_res};
		 } else {
			 # Send and break circular ref
			 $request->{_res}->send if exists $request->{_res}->{client};
			 $request->{_res} = 0;
		 }
	 }
   }
}

sub _error {
   my($heap, $wheel_id) = @_[HEAP, ARG3];
	if(exists $heap->{toclose}->{$wheel_id}) {
		for(@{$heap->{toclose}->{$wheel_id}}) {
			$_->closed;
		}
		delete $heap->{toclose}->{$wheel_id};
	}
   delete $heap->{wheels}->{$wheel_id};

   undef;
}

sub _client_shutdown {
   my($heap, $wheel_id) = @_[HEAP, ARG0];

   delete $heap->{wheels}->{$wheel_id};

   undef;
}

sub _shutdown {
   my($heap, $kernel)  = @_[HEAP, KERNEL];

   return unless defined $heap->{server};

   # Tell TCP server to shutdown
   $kernel->post($heap->{server}, 'shutdown');
   delete $heap->{server};
}

# these are here to help PoCo::FastCGI::Response
# to deal with it's wheel from the right session
sub _w_send {
   my($resp)  = $_[ARG0];
   $resp->_send();
}

sub _w_write {
   my($resp, $out)  = @_[ARG0, ARG1];
   $resp->_write($out);
}

sub _w_close {
   my($resp, $out)  = @_[ARG0, ARG1];
   $resp->_close($out);
}

1;

=head1 NAME

POE::Component::FastCGI - POE FastCGI server

=head1 SYNOPSIS

You can use this module with a direct subroutine callback:

  use POE;
  use POE::Component::FastCGI;

  POE::Component::FastCGI->new(
     Port => 1026,
     Handlers => [
        [ '/' => \&default ],
     ]
  );

  sub default {
     my($request) = @_;

     my $response = $request->make_response;
     $response->header("Content-type" => "text/html");
     $response->content("A page");
     $response->send;
  }

  POE::Kernel->run;

and a POE event callback:

  use POE;
  use POE::Component::FastCGI;

  POE::Component::FastCGI->new(
     Port => 1026,
     Handlers => [
        [ '/' => 'poe_event_name' ],
     ]
     Session => 'MAIN',
  );

  sub default {
     my($request) = @_;

     my $response = $request->make_response;
     $response->header("Content-type" => "text/html");
     $response->content("A page");
     $response->send;
  }

=head1 DESCRIPTION

Provides a FastCGI (L<http://www.fastcgi.com/>) server for L<POE>.

=over 4

=item POE::Component::FastCGI->new([name => value], ...)

Creates a new POE session for the FastCGI server and listens on the specified
port.

Parameters
  Auth (optional)
     A code reference to run when called as a FastCGI authorizer.
  Handlers (required)
     A array reference with a mapping of paths to code references or POE event names.
  Port (required unless Unix is set)
     Port number to listen on.
  Address (requied if Unix is set)
     Address to listen on.
  Unix (optional)
     Listen on UNIX socket given in Address.
  Session (required if you want to get POE callbacks)
     Into which session we should post the POE event back.

The call returns a POE session ID. This should be stored, and when application is to be terminated, a 'shutdown' event can be posted to this session. This will terminate the server socket and free resources.

The handlers parameter should be a list of lists defining either regexps of
paths to match or absolute paths to code references.

The code references will be passed one parameter, a
L<POE::Component::FastCGI::Request> object. To send a response
the C<make_response> method should be called which returns a
L<POE::Component::FastCGI::Response> object. These objects
are subclasses of L<HTTP::Request> and L<HTTP::Response>
respectively.

Example:
   Handlers => [
      [ '/page' => \&page ],
      [ qr!^/(\w+)\.html$! => sub {
           my $request = shift;
           my $response = $request->make_response;
           output_template($request, $response, $1);
        }
      ],
   ]

=back

=head1 USING FASTCGI

Many webservers have support for FastCGI. PoCo::FastCGI has been
tested on Mac OSX and Linux using lighttpd.

Currently you must run the PoCo::FastCGI script separately to the
webserver and then instruct the webserver to connect to it.

Lighttpd configuration example (assuming listening on port 1026):

   $HTTP["host"] == "some.host" {
      fastcgi.server = ( "/" =>
         ( "localhost" => (
            "host" => "127.0.0.1",
            "port" => 1026,
            "check-local" => "disable",
            "docroot" => "/"
            )
         )
      )
   }

With mod_fastcgi on Apache the equivalent directive is
C<FastcgiExternalServer>.

=head1 MAINTAINER

Chris 'BinGOs' Williams on behalf of the POE community

=head1 AUTHOR

Copyright 2005, David Leadbeater L<http://dgl.cx/contact>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please let me know.

=head1 SEE ALSO

L<POE::Component::FastCGI::Request>, L<POE::Component::FastCGI::Response>,
L<POE::Filter::FastCGI>, L<POE>.

=cut
