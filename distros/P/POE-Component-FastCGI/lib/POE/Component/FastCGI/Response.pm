package POE::Component::FastCGI::Response;
BEGIN {
  $POE::Component::FastCGI::Response::VERSION = '0.19';
}

use strict;
use base qw/HTTP::Response/;
use bytes;

use POE::Kernel;

sub new {
   my($class, $client, $id, $code, @response) = @_;
   $code = 200 unless defined $code;

   my $response = $class->SUPER::new($code, @response);

   $response->{client} = $client;
   $response->{requestid} = $id;

   return $response;
}

sub DESTROY {
   my($self) = @_;
   $self->close;
}

sub streaming {
   my($self, $streaming) = @_;
   if(defined $streaming) {
      $self->{streaming} = $streaming;
   }else{
      return $self->{streaming};
   }
}

sub closed {
   my($self, $callback) = @_;
   if(defined $callback) {
      $self->{closed} = $callback;
   }elsif(defined $self->{closed}) {
      $self->{closed}->($self);
   }
}

# Write and send call put() on the wheel. It is imperative that we
# do this from the wheel-owners session. Else we might register event
# handlers in the wrong sessions. For example, when we register the
# FlushedEvent event handler, that would be registered on the wrong
# session, and the wheel would never be closed properly.
sub send {
   my($self) = @_;
   $poe_kernel->call($self->request->{sessionid},
      'w_send', $self);
}

sub write {
   my($self, $out) = @_;
   $poe_kernel->call($self->request->{sessionid},
      'w_write', $self, $out);
   return 1;
}

sub close {
   my($self, $out) = @_;
   return unless defined $self->{client};
   $poe_kernel->call($self->request->{sessionid},
      'w_close', $self, $out);
}


sub _send {
   my($self) = @_;

# Adapted from POE::Filter::HTTPD
   my $status_line = "Status: " . $self->code;

   # Use network newlines, and be sure not to mangle newlines in the
   # response's content.

   $self->header( "Content-Length" => length($self->content) );
   my @headers;
   push @headers, $status_line;
   push @headers, $self->headers_as_string("\x0D\x0A");

   my $filter = $self->{client}->get_input_filter();
   my $keepconn = $filter->{conn}->[$filter->{requestid}]->{keepconn};

   $self->{client}->put({
      requestid => $self->{requestid},
      close => !$keepconn,
      content => join("\x0D\x0A", @headers, "") . $self->content
   });

   ### FCGI_KEEP_CONN: disconnect after request if NOT set:
   if($keepconn == 0) {
      $self->{client}->event( FlushedEvent => "client_shutdown" );
   }

   # Kill circular ref & delete wheel reference
   $self->request->{_res} = 0;
   delete $self->{client};
   return 1;
}

sub _write {
   my($self, $out) = @_;
   $self->{client}->put({requestid => $self->{requestid}, content => $out});
}

sub _close {
   my($self, $out) = @_;
   $self->{client}->put({
      requestid => $self->{requestid},
      close => 1,
      content => ""
   });

   # Kill circular ref & delete wheel reference
   $self->request->{_res} = 0;
   delete $self->{client};
   return 1;
}

sub redirect {
   my($self, $url, $uri) = @_;
   $url = defined $self->request
      ?  URI->new_abs($url, $self->request->uri)
      : $url;

   $self->code(302);
   $self->header(Location => $url);
}

sub error {
   my($self, $code, $text) = @_;
   $self->code($code);
   $self->header("Content-type" => "text/html");
   $self->content(defined $text ? $text : $self->error_as_HTML);
   $self->send;
}

1;

=head1 NAME

POE::Component::FastCGI::Response - PoCo::FastCGI HTTP Response class

=head1 SYNOPSIS

   use POE::Component::FastCGI::Response;
   my $response = POE::Component::FastCGI::Response->new($client, $id,
      200, ..  HTTP::Response parameters ..);

=head1 DESCRIPTION

This module is generally not used directly, you should call
L<POE::Component::FastCGI::Request>'s C<make_response> method which
returns an object of this class.

C<POE::Component::FastCGI::Response> is a subclass of L<HTTP::Response>
so inherits all of its methods. The includes C<header()> for setting output
headers and C<content()> for setting the content.

Therefore the following methods mostly deal with actually sending the
response:

=over 4

=item $response = POE::Component::FastCGI::Response->new($client, $id, $code)

Creates a new C<POE::Component::FastCGI::Response> object, parameters from
C<$code> onwards are passed directly to L<HTTP::Response>'s constructor.

=item $response->streaming

Set and check streaming status

=item $response->closed

Set a callback to be called when this response is closed, mainly useful for
streaming.

=item $response->send

Sends the response object and ends the current connection.

=item $response->write($text)

Writes some text directly to the output stream, for use when you don't want
to or can't send a L<HTTP::Response> object.

=item $response->close

Closes the output stream.

You don't normally need to use this as the object will automatically close
when DESTROYed.

=item $response->redirect($url)

Sets the object to be a redirect to $url. You still need to call C<send> to
actually send the redirect.

=item $response->error($code, $text)

Sends an error to the client, $code is the HTTP error code and $text is
the content of the page to send.

=back

=head1 AUTHOR

Copyright 2005, David Leadbeater L<http://dgl.cx/contact>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please let me know.

=head1 SEE ALSO

L<POE::Component::FastCGI::Request>, L<HTTP::Response>,
L<POE::Component::FastCGI>, L<POE>.

=cut
