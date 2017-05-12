package mySOAP::Client;
use base qw ( Aw::Client );


sub publish
{
my ($self, $request, $timeout) = @_ ;


    # clearQue is not important until we go back to persistent aw clients.
    #
    # $self->clearQue;   # flush anything that timedout previously

    my $event = undef;
    $event = ( $self->SUPER::publish ( $request ) )
           ? undef
           : $self->getEvent ( $timeout );

    return ( {errorText => "NullReply"} ) if ( !$event || $event->isNullReply );

    my %hash = $event->toHash;
    $event->delete;
    $event = undef;

    # $self->clearQue;   # flush anything that timedout previously

    \%hash;
}



# ======================================================================

package SOAP::Transport::ACTIVEWORKS;
use base qw( Exporter );


BEGIN:
{
	use strict;
	use vars qw(
		$AW_DEFAULT_HOST
		$AW_DEFAULT_PORT
		$AW_DEFAULT_BROKER
		$AW_DEFAULT_CLIENT_GROUP
		$AW_DEFAULT_METHOD_URI
		$AW_DEFAULT_ENDPOINT
		$AW_REQUEST_TIMEOUT
		$VERSION
		@EXPORT
	);

	$AW_DEFAULT_HOST         = "my.active.host";
	$AW_DEFAULT_PORT         = 6849;
	$AW_DEFAULT_BROKER       = "SOAP";
	$AW_DEFAULT_CLIENT_GROUP = "SOAP";
	$AW_DEFAULT_METHOD_URI   = "urn:com-name-your";
	$AW_DEFAULT_ENDPOINT     = "$AW_DEFAULT_BROKER:$AW_DEFAULT_CLIENT_GROUP\@$AW_DEFAULT_HOST:$AW_DEFAULT_PORT";
	$AW_REQUEST_TIMEOUT      = 20000;
	$VERSION = '0.45';

	@EXPORT = qw(
		$AW_DEFAULT_HOST
		$AW_DEFAULT_PORT
		$AW_DEFAULT_BROKER
		$AW_DEFAULT_CLIENT_GROUP
		$AW_DEFAULT_METHOD_URI
		$AW_DEFAULT_ENDPOINT
		$AW_REQUEST_TIMEOUT
		$VERSION
	);
}



# ======================================================================

package SOAP::Transport::ACTIVEWORKS::Serializer;

use vars qw(@ISA);
@ISA = qw(SOAP::Serializer);

use SOAP::Lite;

sub encode_object {

  my $self = shift;

  ( ref($_[0]) eq "Aw::Date" )
    ? $self->encode_scalar($_[0]->toString, $_[1], "string", $_[3])
    : $self->SUPER::encode_object ( @_ ) 
  ;

}



# ======================================================================

package SOAP::Transport::ACTIVEWORKS::Client;

require Aw::Client;
require Aw::Event;

use vars qw(@ISA);
@ISA = qw(SOAP::Client);

use SOAP::Lite;
use SOAP::Transport::ACTIVEWORKS;

sub DESTROY { SOAP::Trace::objects('()') }

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $blessing;

  unless (ref $self) {
    my(@params, @methods);
    $self = {};
    $blessing = bless ( $self, $class );
    while (@_) { $class->can($_[0]) ? push(@methods, shift() => shift) : push(@params, shift) }
    while (@methods) { my($method, $params) = splice(@methods,0,2);
      $self->$method(ref $params eq 'ARRAY' ? @$params : $params) 
    }
    SOAP::Trace::objects('()');
    return $blessing;
  }

  $self;
}


sub send_receive {
  my($self, %parameters) = @_;
  my($envelope, $endpoint, $action, $alt_uri) = 
    @parameters{qw(envelope endpoint action alt_uri)};

    $action =~ s/"//g;
    $endpoint ||= $self->endpoint;

    my $location = ( $endpoint =~ m|activeworks://|i ) ? $endpoint : $action;

    $location  =~ s|(\w+):(//)?||;
    my $scheme = $1;

    $location      =~ s|/(.*)||;
    my $event_type = $1;

    if ( ($scheme ne $event_type)  && $scheme !~ /^urn$/i ) {
      $event_type =~ s/#(.*)//;
      $event_type =~ s|/|::|g;    # map class path back to event
    }
    else {
      $event_type =  "SOAP::Request";
    }

    $action    =~ /#(.*)/;
    my $method_name = $1;

    my ($broker_group, $host)   = split ("@", $location);
    my ($broker, $client_group) = split (":", $broker_group);

    if ( $alt_uri ) {
      my $alt_location = $alt_uri;

      $alt_location =~ s|(\w+):(//)?||;
      $alt_location =~ s|/(.*)||;
	
      my ($alt_broker_group, $alt_host)   = split ("@", $alt_location);
      my ($alt_broker, $alt_client_group) = split (":", $alt_broker_group);

      $host         ||=  $alt_host;
      $broker       ||=  $alt_broker;
      $client_group ||=  $alt_client_group;
    }

    $host         ||= "$SOAP::Transport::ACTIVEWORKS::AW_DEFAULT_HOST:$SOAP::Transport::ACTIVEWORKS::AW_DEFAULT_PORT";
    $broker       ||=  $SOAP::Transport::ACTIVEWORKS::AW_DEFAULT_BROKER;
    $client_group ||=  $SOAP::Transport::ACTIVEWORKS::AW_DEFAULT_CLIENT_GROUP;

    my $ua = new mySOAP::Client ( "$host", $broker, "", $client_group, "SOAP::Client" );

    my $post = new Aw::Event ( $ua, $event_type );

    my $timeout = $SOAP::Transport::ACTIVEWORKS::AW_REQUEST_TIMEOUT;
		  
    if ( $client_group ne "SOAP" ) {
      my $request = SOAP::Deserializer->deserialize ( $envelope );
      my $x = $request->paramsout;
      $x    = $request->paramsin  unless ( ref ($x) eq "SOAPStruct" );
      if ( $x ) {
        my %eventData = %{$x};
        $post->setField ( \%eventData );
        $timeout = $eventData{_event_timeout} if ( $eventData{_event_timeout} );
      }
    }
    else {
      $post->setField ( envelope       => $envelope );

      $post->setField ( SOAPAction     => $action );

      $post->setField ( DebugRequest   => '1') if ( $self->{debug_request} );

      $post->setField ( Content_Type   => 'text/xml' );

      $post->setField ( Content_Length => length($envelope) );
    }
    
    my $aw_response = $ua->publish ( $post, $timeout );

    my $content;
    #
    # Check for Aw Errors
    #
    if ( $aw_response->{errorText} ) {
	$content = SOAP::Serializer->fault ( $SOAP::Constants::FAULT_SERVER, 'Application error' => "Application failed: $aw_response->{errorText}" );
	$self->is_success (0);
    }
    elsif ( $client_group ne "SOAP" ) {
        $content =  SOAP::Transport::ACTIVEWORKS::Serializer
                 -> prefix('s')
                 -> uri($action)
                 -> envelope (
                       method => $method_name . 'Response',
                       $aw_response
                 );
    }
    else {
    	$content = $aw_response->{envelope};
	$self->is_success (1);
    }


    $content;

}

# ======================================================================

package SOAP::Transport::ACTIVEWORKS::ProxyServer;

use vars qw(@ISA);
@ISA = qw(SOAP::Server);

use SOAP::Transport::ACTIVEWORKS;

sub DESTROY { SOAP::Trace::objects('()') }

sub new { require LWP::UserAgent;
  my $self = shift;
  my $class = ref($self) || $self;

  unless (ref $self) {
    $self = $class->SUPER::new(@_);
    $self->on_action(sub {
      (my $action = shift) =~ s/^("?)(.*)\1$/$2/;
      die "SOAPAction shall match 'uri#method' if present\n" 
        if $action && $action ne join('#', @_) && $action ne join('/', @_);
    });
    SOAP::Trace::objects('()');
  }
  return $self;
}

sub BEGIN {
  no strict 'refs';
  for my $method (qw(request response)) {
    my $field = '_' . $method;
    *$method = sub {
      my $self = shift->new;
      @_ ? ($self->{$field} = shift, return $self) : return $self->{$field};
    }
  }
}

sub handle {
  my $self = shift->new;

  return $self->response(HTTP::Response->new(400)) # BAD_REQUEST
    unless $self->request->method eq 'POST';

  return $self->make_fault($SOAP::Constants::FAULT_CLIENT, 'Bad Request' => 'Content-Type must be text/xml')
    unless $self->request->content_type eq 'text/xml';

  my $awua = new SOAP::Transport::ACTIVEWORKS::Client; 

  my $response  =  $awua->send_receive(
    endpoint    => $SOAP::Transport::ACTIVEWORKS::AW_DEFAULT_ENDPOINT,
    action      => $self->request->header('SOAPAction'),
    envelope    => $self->request->content,
  );

  if ( $response =~ "SOAP-ENV:Fault" ) {
      $self->response(HTTP::Response->new( 
         $SOAP::Constants::HTTP_ON_FAULT_CODE => undef,
         HTTP::Headers->new('Content-Type' => 'text/xml', 'Content-Length' => length $response), 
         $response,
      ));
  }
  else {
      $self->response(HTTP::Response->new( 
         $SOAP::Constants::HTTP_ON_SUCCESS_CODE => undef, 
         HTTP::Headers->new('Content-Type' => 'text/xml', 'Content-Length' => length $response), 
         $response,
      ));
  }

}

sub make_fault {
  my $self = shift;
  my $response = $self->SUPER::make_fault(@_);
  $self->response(HTTP::Response->new(
     $SOAP::Constants::HTTP_ON_FAULT_CODE => undef,
     HTTP::Headers->new('Content-Type' => 'text/xml', 'Content-Length' => length $response),
     $response,
  ));
  return;
}

# ======================================================================

package SOAP::Transport::ACTIVEWORKS::CGI;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::ACTIVEWORKS::ProxyServer);

sub DESTROY { SOAP::Trace::objects('()') }

sub new { 
  my $self = shift;
  my $class = ref($self) || $self;

  unless (ref $self) {
    $self = $class->SUPER::new(@_);
    SOAP::Trace::objects('()');
  }
  return $self;
}

sub handle {
  my $self = shift->new;

  my $content; read(STDIN,$content,$ENV{'CONTENT_LENGTH'} || 0);  
  $self->request(HTTP::Request->new( 
    $ENV{'REQUEST_METHOD'} || '' => $ENV{'SCRIPT_NAME'},
    HTTP::Headers->new(map {(/^HTTP_(.+)/i ? $1 : $_) => $ENV{$_}} keys %ENV),
    $content,
  ));
  $self->SUPER::handle;

  my $code = $self->response->code;
  binmode(STDOUT); print STDOUT 
    "Status: $code ", HTTP::Status::status_message($code), 
    "\015\012", $self->response->headers_as_string, 
    "\015\012", $self->response->content;
}

# ======================================================================

package SOAP::Transport::ACTIVEWORKS::Daemon;

use Carp;
use vars qw($AUTOLOAD @ISA);
@ISA = qw(SOAP::Transport::ACTIVEWORKS::ProxyServer);

sub DESTROY { SOAP::Trace::objects('()') }

sub new { eval "use HTTP::Daemon"; die if $@;
  my $self = shift;
  my $class = ref($self) || $self;

  unless (ref $self) {
    $self = $class->SUPER::new();
    $self->{_daemon} = HTTP::Daemon->new(@_) or croak "Can't create daemon: $!";
    SOAP::Trace::objects('()');
  }
  return $self;
}

sub AUTOLOAD {
  my($method) = $AUTOLOAD =~ m/([^:]+)$/;
  return if $method eq 'DESTROY';

  no strict 'refs';
  *$AUTOLOAD = sub { shift->{_daemon}->$method(@_) };
  goto &$AUTOLOAD;
}

sub handle {
  my $self = shift->new;
  while (my $c = $self->accept) {
    while (my $r = $c->get_request) {
      $self->request($r);
      $self->SUPER::handle;
      $c->send_response($self->response)
    }
    $c->close;
    undef $c;
  }
}

# ======================================================================

package SOAP::Transport::ACTIVEWORKS::Apache;

use vars qw(@ISA);
@ISA = qw(SOAP::Transport::ACTIVEWORKS::ProxyServer);

sub DESTROY { SOAP::Trace::objects('()') }

sub new { eval "use Apache; use Apache::Constants qw(OK)"; die if $@;
  my $self = shift;
  my $class = ref($self) || $self;

  unless (ref $self) {
    $self = $class->SUPER::new(@_);
    SOAP::Trace::objects('()');
  }
  return $self;
}

sub handler { 
  my $self = shift->new; 
  my $r = shift || Apache->request; 

  $self->request(HTTP::Request->new( 
    $r->method => $r->uri,
    HTTP::Headers->new(
      'Content-Type' => $r->header_in('Content-type'),
      'SOAPAction' => $r->header_in('SOAPAction'),
    ),
    do { my $buf; $r->read($buf, $r->header_in('Content-length')); $buf; } 
  ));
  $self->SUPER::handle;

  my $header = $self->response->is_success ? 'header_out' : 'err_header_out';
  $r->$header('Content-length' => $self->response->content_length);
  $r->content_type($self->response->content_type);
  $r->status($self->response->code); 
  $r->send_http_header;
  $r->print($self->response->content) unless $r->header_only;

  &OK;
}

*handle = \&handler; # just create alias

# ======================================================================

1;

__END__

=head1 NAME

 SOAP::Transport::ACTIVEWORKS - Server/Client side ActiveWorks support for SOAP::Lite for Perl

=head1 SYNOPSIS


 use SOAP::Lite +autodispatch =>
   uri      => 'activeworks://myBroker:clientGroup@my.active.host:7449',
   proxy    => 'http://my.http.host/aw-soap/',
   on_fault => sub { my($soap, $res) = @_;
     die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
   }
 ;

 print "Remote Time is ", ${ AdapterDevKit::timeRequest->SOAP::publish }{time}, "\n";


=head1 DESCRIPTION

The SOAP::Transport::ACTIVEWORKS class provides support for ActiveWorks
URIs to access ActiveWorks brokers through an HTTP proxy server with
SOAP structured requests.  The package also allows an ActiveWorks adapter
to be used as a SOAP server to either invoke arbitrary Perl classes or
to publish and return ActiveWorks events specified in a SOAP structure.

This class mirrors the interface of the SOAP::Transport::HTML class
which should be referred to for general documentation.  The URI differences
will be discussed here with example usage.


=head2 ACTIVEWORKS URI COMPONENTS

The general schema of an ActiveWorks URI is as follows:

  activeworks://<broker>:<client group>@<host>:<port>

All parameters are optional and defaults can be set within the B<BEGIN>
section of the SOAP::Transport::ActiveWorks package.  The assumed
client group is always 'SOAP' and SOAP requests are forwarded to a
SOAP adapter (B<server/soap_adapter.pl> is provided) assumed to be
running on the default broker.

If an alternative client group is specified the SOAP request is
assumed to contain fields corresponding to a named ActiveWorks
event available on the broker.  See section C<PSEUDO EVENTS> for
details.



=head2 HTTP PROXY SETTINGS

When using an HTTP server to proxy publish AW events the 'proxy' autodispatcher
parameter should be set to your SOAP server URI as you would with a normal
SOAP request.


 use SOAP::Lite +autodispatch =>
   uri      => 'urn:', # use default broker, client group, etc.
   proxy    => 'http://my.http.host/aw-soap/',
   on_fault => sub { my($soap, $res) = @_;
     die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
   }
 ;


Note that the SOAP server, 'aw-soap' in this case, must be enabled to
dispatch requests to an ActiveWorks handler.  The provided Apache::AwSOAP
module demonstrates this:

 package Apache::AwSOAP;

 use strict;
 use Apache;
 use SOAP::Transport::ACTIVEWORKS;

 my $server = SOAP::Transport::ACTIVEWORKS::Apache
    -> dispatch_to( '' );


 sub handler { $server->handler(@_); }

 1;


The B<client/http-aw-soap-aw-calculator.pl> script demonstrates relaying a SOAP
envelope from an http server to an ActiveWorks adapter for processing.

To work with your normal soap server, the AwGateway module may be used to
relay an ordinary SOAP request as an ActiveWorks event to a broker
specified in the autodispatcher 'uri' parameter.  See section C<AwGateway>.


=head2 USING AN ACTIVEWORKS BROKER AS A SOAP SERVER

The ACTIVEWORKS module along with the B<soap-lite-adapter.pl> allows you
to use an ActiveWorks broker as a SOAP server.  Like a normal http server
the SOAP adapter will instantiate and invoke the class and method specified
in a SOAP request.  In addition, classes may be mapped onto ActiveWorks
events (see section C<PSEUDO CLASSES>), mapped onto an adapter subroutine for
special handling (see B<http-callback-aw-aw-time.pl> for a demonstration) and
even relayed to an http SOAP server specified in the method URI (see
B<aw-soap-aw-http-calculator.pl> for example usage).

The B<soap-lite-adapter.pl> allows an  ActiveWorks client to send and receive
requests to a broker with a SOAP envelope to take advantage of the SOAP
protocol in a purely ActiveWorks environment.


=head2 PSEUDO CLASSES

ActiveWorks events may be instantiated and published much like remote
classes.  With a 'pseudo class' we treat the remote event as if it were
just another SOAP class that we want to access remotely.

The difference will be that we can only send a hash reference as
an argument and always get a hash type in return (which is in
keeping with the Aw package treatment of events as hashes).
Also we publish the event with the dummy method '->publish'.


 use SOAP::Lite +autodispatch =>
   uri      => 'activeworks://myBroker:clientGroup@my.active.host:7449',
   proxy    => 'http://my.http.host/aw-soap/',
   on_fault => sub { my($soap, $res) = @_;
     die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
   }
 ;

  #
  # Hash are used to transport ActiveWorks request event data:
  #
  my %request = ();

  #
  # Populate the event fields:
  #
  $request{numbers} = \@Numbers;

  #
  # Reset default publish timeout from 20 seconds:
  #
  $request{_event_timeout} = 40000;

  #
  # Publish event and force returned SOAPStruct type into a hash:
  #
  my %results = %{ AdapterDevKit::calcRequest->SOAP::publish ( \%request ) };



The client script B<http-pseudo-aw-aw-calculator.pl> and
B<http-pseudo-aw-aw-time.pl> demonstrate pseudo class usage.


=head2 AwGateway

The AwGateway module is a normal SOAP module that you would keep in your
"Deployed Modules" directory.  With AwGateway you access an ActiveWorks
broker through your usual SOAP server and bi-pass the ACTIVEWORKS module
altogether.

See the AwGateway full documentation and the accompanying client script
B<http-gateway-aw-aw-calculator.pl> demonstration use.


=head1 DEPENDENCIES

 The Aw package for Perl interfaces to ActiveWorks libraries.
 The SOAP-Lite package.

=head1 SEE ALSO

 See SOAP::Transport::HTTP

=head1 COPYRIGHT

Copyright (C) 2000 Paul Kulchenko. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

The SOAP::Transport::ACTIVEWORKS module was developed by Daniel Yacob
and is derived directly from SOAP::Transport::HTTP by Paul Kulchenko.

 Daniel Yacob,  L<yacob@rcn.com|mailto:yacob@rcn.com>
 Paul Kulchenko,  L<paulclinger@yahoo.com|mailto:paulclinger@yahoo.com>

=cut
