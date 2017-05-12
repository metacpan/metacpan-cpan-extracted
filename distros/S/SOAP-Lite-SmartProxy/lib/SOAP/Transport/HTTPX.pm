# ======================================================================
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: SOAP::Transport::HTTP.pm,v 0.46 2001/01/31 16:30:24 $
#
# ======================================================================

package SOAP::Transport::HTTPX;

use strict;
use vars qw($VERSION);
$VERSION = '0.46';

use SOAP::Transport::HTTP;

# ======================================================================

package SOAP::Transport::HTTPX::Client;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::HTTP::Client); 

use SOAP::Lite;

my(%redirect, %mpost);


sub send_receive {
  my($self, %parameters) = @_;
  my($envelope, $endpoint, $action) = 
    @parameters{qw(envelope endpoint action)};

  $endpoint ||= $self->endpoint;

  $endpoint =~ s|httpx://|http://|;
  my $method = 'POST';
  my $resp;

  my $redir_count = 0;
  while (1) { 

    # check cache for redirect
    $endpoint = $redirect{$endpoint} if exists $redirect{$endpoint};
    # check cache for M-POST
    $method = 'M-POST' if exists $mpost{$endpoint};

    my $req = HTTP::Request->new($method => $endpoint, HTTP::Headers->new, $envelope);
    $req->proxy_authorization_basic($ENV{'HTTP_proxy_user'}, $ENV{'HTTP_proxy_pass'})
      if ($ENV{'HTTP_proxy_user'} && $ENV{'HTTP_proxy_pass'}); # by Murray Nesbitt 

    if ($method eq 'M-POST') {
      my $prefix = sprintf '%04d', int(rand(1000));
      $req->header(Man => qq!"$SOAP::Constants::NS_ENV"; ns=$prefix!);
      $req->header("$prefix-SOAPAction" => $action);  
    } else {
      $req->header(SOAPAction => $action);
    }
    $req->content_type('text/xml');
    $req->content_length(length($envelope));

    SOAP::Trace::transport($req);
    SOAP::Trace::debug($req->as_string);
    
    $self->SUPER::env_proxy if $ENV{'HTTP_proxy'};

    $resp = $self->SUPER::request($req);

    SOAP::Trace::transport($resp);
    SOAP::Trace::debug($resp->as_string);

    # 100 OK, continue to read?
    if (($resp->code == 510 || $resp->code == 501) && 
        $method ne 'M-POST') { 
      $mpost{$endpoint} = 1;
    } elsif ( $resp->code == 301 && $redir_count++ < 10 ) {
	  my $head = $resp->headers;
	  if ( $head->{soapaction} ) {
		my ($oldclass) = $action =~ m/(.*)#/;
		my $newaction = $action = $head->{soapaction};
		my ($newclass) = $newaction =~ m/(.*)#/;
		$envelope =~ s/$oldclass/$newclass/;
	  }
	  $endpoint = $head->{location} if ( $head->{location} );
    } else {
      last;
    }
  }


  $redirect{$endpoint} = $resp->request->url
    if $resp->previous && $resp->previous->is_redirect;

  $self->code($resp->code);
  $self->message($resp->message);
  $self->is_success($resp->is_success);
  $self->status($resp->status_line);

  join '', $resp->content_type =~ m!^multipart/! ? ($resp->headers_as_string, "\n") : '',
           $resp->content;
}

# ======================================================================

package SOAP::Transport::HTTPX::Server;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::HTTP::Server);

# ======================================================================

package SOAP::Transport::HTTPX::CGI;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::HTTP::CGI);

# ======================================================================

package SOAP::Transport::HTTPX::Daemon;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::HTTP::Daemon);

# ======================================================================

package SOAP::Transport::HTTPX::Apache;

use vars qw(@ISA %Redirect $hc);
@ISA = qw(SOAP::Transport::HTTP::Apache);

my ( $forward, $redirect ) = ( 0, 1 );

sub handler { 
  my $self = shift->new; 
  my $r = shift || Apache->request; 

  $self->request(HTTP::Request->new( 
     $r->method => $r->uri,
     HTTP::Headers->new($r->headers_in),
     do { my $buf; $r->read($buf, $r->header_in('Content-length')); $buf; } 
  ));

  my $action = my $orig_action = $self->request->header('SOAPAction');

  $action    =~ s|"||g;
  $action    =~ s|(\w+:)(/+)?||;
  my $scheme = $1.$2;

  my ( $class, $method ) = $action =~ m|(.*?)#(.*)|;
  $class  =~ s|/|::|g;

  unless ( %Redirect ) {
	foreach ( $self->dispatch_to() ) {
		push (@INC, $_ ) if m|/|;
	}
	eval "use Redirect"; die if $@;
  }

  if ( exists($Redirect{$class}) ) {
    my $re_proxy = $Redirect{$class}->[0];
    my $re_class = $Redirect{$class}->[1];

    $re_class = "urn:/$re_class" if ( $re_class && $re_class !~ /^\w+:/ );
    my $new_action = ( $re_class ) ? "\"$re_class#$method\"" : $orig_action;

    if ( $Redirect{$class}->[2] == $redirect ) {
      $r->header_out( 'SOAPAction' => $new_action );
      $r->header_out( 'Location'   => $re_proxy  );
      $r->status(301);
      $r->send_http_header;
      return 301;
    }
    elsif ( exists($Redirect{$class}) && $Redirect{$class}->[2] == $forward ) {
      my $content = $self->request->content;
      $content =~ s/$scheme$class/$re_class/ if ( $re_class );

      $hc ||= SOAP::Transport::HTTP::Client->new;

      my $response = $hc->send_receive (
        envelope => $content,
        endpoint => $re_proxy,
        action   => $new_action,
      );

      $response =~ s/$re_class/$class/ if ( $re_class );

      if ($hc->is_success) {
         $r->header_out('Content-Length' => length ($response) );
         $r->send_http_header($hc->{response}->content_type);
         $r->print($response);
      } else {
         $r->err_header_out('Content-length' => length ($response) );
         $r->content_type($hc->{response}->content_type);
         $r->custom_response($hc->code, $response);
      }
      return $hc->code;
    }
  }


  SOAP::Transport::HTTP::Server::handle ( $self );


  if ($self->response->is_success) {
    $r->header_out('Content-length' => $self->response->content_length);
    $r->send_http_header($self->response->content_type);
    $r->print($self->response->content);
  } else {
    $r->err_header_out('Content-length' => $self->response->content_length);
    $r->content_type($self->response->content_type);
    $r->custom_response($self->response->code, $self->response->content);
  }

  $self->response->code;

}

# ======================================================================


1;

__END__

=head1 NAME

SOAP::Transport::HTTPX - Server/Client side HTTP Smart Proxy for SOAP::Lite

=head1 SYNOPSIS

 use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'httpx://my.smart.server/soap',
    on_fault => sub { my($soap, $res) = @_; 
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
 ;


 print Hello->SOAP::echo ( 'Paul' ), "\n";


=head1 DESCRIPTION

The SmartProxy package is intended for use in a multi-server setting where
one or more servers may not be directly accessible to client side scripts.
The SmartProxy package makes request redirection and forwarding on a per class
basis easy.  Client scripts need not know which server is appropriate for a
specific request and may make all requests from a single master server which
can be relied upon to redirect clients to the server currently fulfilling a
given request.  The relieves a maintenance burden on the client side.  The
server may also redirect clients to a new class name or fully qualified
action URI (methods and arguments are assumed to remain constant however).


=head1 DEPENDENCIES

 The SOAP-Lite package.

=head1 SEE ALSO

 See SOAP::Transport::HTTP

=head1 COPYRIGHT

Copyright (C) 2000-2001 Paul Kulchenko. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

 Daniel Yacob (yacob@rcn.com)
 Paul Kulchenko (paulclinger@yahoo.com)

=cut
