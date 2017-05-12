package POE::Component::FastCGI::Request;
BEGIN {
  $POE::Component::FastCGI::Request::VERSION = '0.19';
}

use strict;

use CGI::Util qw(unescape);
use HTTP::Headers;
use base qw/HTTP::Request/;

use POE::Component::FastCGI::Response; # for make_response

sub new {
   my($class, $client, $sessionid, $id, $cgi, $query) = @_;
   my $host = defined $cgi->{HTTP_HOST} ? $cgi->{HTTP_HOST} :
      $cgi->{SERVER_NAME};

   my $self = $class->SUPER::new(
      $cgi->{REQUEST_METHOD},
      "http" .  (defined $cgi->{HTTPS} and $cgi->{HTTPS} ? "s" : "") .
         "://$host" . $cgi->{REQUEST_URI},
      # Convert CGI style headers back into HTTP style
      HTTP::Headers->new(
         map {
            my $p = $_;
            s/^HTTP_//;
            s/_/-/g;
            ucfirst(lc $_) => delete $cgi->{$p};
         } grep /^HTTP_/, keys %$cgi
      ),
      $query
   );

   $self->{client} = $client;
   $self->{sessionid} = $sessionid;
   $self->{requestid} = $id;
   $self->{env} = $cgi;

   return $self;
}

sub DESTROY {
   my $self = shift;
   if(not exists $self->{_res}) {
      warn __PACKAGE__ . " object destroyed without sending response";
   }
}

sub make_response {
   my($self, $response) = @_;

   if(not defined $response) {
      $response = POE::Component::FastCGI::Response->new(
         $self->{client},
         $self->{requestid},
      );
      $self->{_res} = $response;
      $response->request($self);
      return $response;
   }

   if(not $response->isa("POE::Component::FastCGI::Response")) {
      bless $response, "POE::Component::FastCGI::Response";
   }

   $response->{client} = $self->{client};
   $response->{requestid} = $self->{requestid};
   $response->request($self);
   $self->{_res} = $response;

   return $response;
}

sub error {
   my($self, $code, $text) = @_;
   warn "Error $code: $text\n";
   $self->make_response->error($code, $text);
}

sub env {
   my($self, $env) = @_;
   if(exists $self->{env}->{$env}) {
      return $self->{env}->{$env};
   }
   return undef;
}

sub query {
   my($self, $param) = @_;

   if(not exists $self->{_query}) {
      if($self->method eq 'GET') {
         $self->{_query} = _parse(\$self->{env}->{QUERY_STRING});
      }else{
         $self->{_query} = _parse($self->content_ref);
      }
   }

   if(not defined $param) {
      return $self->{_query};
   }elsif(exists $self->{_query}->{$param}) {
      return $self->{_query}->{$param};
   }
   return undef;
}

sub cookie {
   my($self, $name) = @_;

   if(not exists $self->{_cookie}) {
      return undef unless defined $self->header("Cookie");
      $self->{_cookie} = _parse(\$self->header("Cookie"));
   }

   return $self->{_cookie} if not defined $name;

   return $self->{_cookie}->{$name} if exists $self->{_cookie}->{$name};

   return undef;
}

sub _parse {
   my $string = shift;
   my $res = {};
   for(split /[;&] ?/, $$string) {
      my($n, $v) = split /=/, $_, 2;
      $v = unescape($v);
      $res->{$n} = $v;
   }
   return $res;
}

1;

=head1 NAME

POE::Component::FastCGI::Request - PoCo::FastCGI HTTP Request class

=head1 SYNOPSIS

   use POE::Component::FastCGI::Request;
   my $response = POE::Component::FastCGI::Response->new($client, $id,
      $cgi, $query);

=head1 DESCRIPTION

Objects of this class are generally created by L<POE::Component::FastCGI>,

C<POE::Component::FastCGI::Request> is a subclass of L<HTTP::Response>
so inherits all of its methods. The includes C<header()> for reading
headers.

It also wraps the enviroment variables found in FastCGI requests, so
information such as the client's IP address and the server software
in use is available.

=over 4

=item $request = POE::Component::FastCGI::Request->new($client, $id, $cgi, $query)

Creates a new C<POE::Component::FastCGI::Request> object. This deletes values
from C<$cgi> while converting it into a L<HTTP::Request> object.
It also assumes $cgi contains certain CGI variables. This generally should
not be used directly, POE::Component::FastCGI creates these objects for you.

=item $response = $request->make_response([$response])

Makes a response object for this request or if the optional parameter is
provided turns a normal HTTP::Response object into a
POE::Component::FastCGI::Response object that is linked to this request.

=item $request->error($code[, $text])

Sends a HTTP error back to the user.

=item $request->env($name)

Gets the specified variable out of the CGI environment.

eg:
   $request->env("REMOTE_ADDR");

=item $request->query([$name])

Gets the value of name from the query (GET or POST data).
Without a parameter returns a hash reference containing all
the query data.

=item $request->cookie([$name])

Gets the value of the cookie with name from the request.
Without a parameter returns a hash reference containing all
the cookie data.

=back

=head1 AUTHOR

Copyright 2005, David Leadbeater L<http://dgl.cx/contact>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please let me know.

=head1 SEE ALSO

L<POE::Component::FastCGI::Response>, L<HTTP::Request>,
L<POE::Component::FastCGI>, L<POE>.

=cut
