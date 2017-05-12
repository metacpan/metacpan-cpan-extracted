package POE::Component::Client::SOAP;

use warnings;
use strict;
our @EXPORT = ( );
use Switch;

use Carp qw(croak);
use POE;
use POE::Component::Generic;
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.01';

use POE::Component::Client::SOAP::Nonblock;

#my @reconnections = qw(60 120 240 480 960 1920 3840);
my @reconnections = qw(1 2 3);

#TODO: Take a look at Proc::BackOff

our $soap_config; #lexical scope

sub spawn {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my %args = @_;
  my $self = bless ({}, $package);

  $args{Alias} = 'soap-client' unless $args{Alias};
  croak "$package missing SOAP proxy" unless $args{proxy};
  croak "$package missing SOAP service" unless $args{service};
  $args{retry_reconnect} = 0 unless $args{retry_reconnect};


  $self->{CONFIG} = \%args;
  $soap_config = $self->{CONFIG}; #lexical scope

  $self->{count} = scalar(@reconnections);
  $self->{attempts} = 0;

  POE::Session->create(
    object_states => [
      $self => {
        _start => '_client_start',
        _stop => '_client_stop',
        shutdown => '_client_close',
        reconnect => '_server_connect',
      },
      $self => [ qw( child_sig _server_connect _client_close _pocog_error
                     _soap_response _soap_result _handle_error
                     handle_result handle_error handle_connected) ],
    ],
    (ref $args{options} eq 'HASH' ? (options => $args{options}) : () ),
  );

  return $self;
}

# only for debug
sub child_sig {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->log($kernel, 'debug', "CHLD:".$_[ARG1]);
}

sub _client_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->log($kernel, 'debug', '_client_start()');
  $kernel->alias_set($self->config('Alias'));
  $kernel->sig(CHLD => 'child_sig');
  $kernel->yield('_server_connect');
}

sub _client_stop {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->log($kernel, 'debug', '_client_stop()');
}

sub _client_close {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->log($kernel, 'debug', '_client_close()');
  $self->handle_shutdown($kernel);
  $kernel->alias_remove($self->config('Alias'));
}


sub _server_connect {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->log($kernel, 'debug', '_server_connect()');

  # TODO: trusting PoCo::Generic not to leak PIDs. This needs further
  # revision.  Don't know what PoCo:Generic does with dead childs and
  # how to handle them.

  unless(defined $self->{soap} and defined $self->{soap}->{litex}){
    $self->{soap}->{litex} = undef;
    $self->{soap} = undef;
    my $soap = POE::Component::Client::SOAP::Nonblock->new($self->{CONFIG});
    if (defined $soap) {
      $self->{soap} = $soap;
    }
    else {
      $self->_reconnect($kernel);
    }
  }

  $kernel->yield('handle_connected');
  $self->{please_wait} = 0;

}


# log any poco generic errors
sub _pocog_error {
  my( $kernel, $self, $session, $err ) = @_[ KERNEL, OBJECT, SESSION, ARG0 ];
  my $errstr = undef;
  unless($err->{stderr}){
    my $op = $err->{operation}?$err->{operation}:'undef';
    my $en = $err->{errnum}?$err->{errnum}:'undef';
    my $es = $err->{errstr}?$err->{errstr}:'undef';
    $errstr = qq|OP:$op EN:$en ES:$es|;
    $self->log($kernel, 'error', "_pocog_error() wheel error: $errstr");
    $self->{pocog_error} = 1;
  }
}

sub _reconnect {
  my ($self, $kernel) = @_;

  $self->log($kernel, 'debug', "Attempts: $self->{attempts}, Count: $self->{count}");
  if ($self->{attempts} < $self->{count}) {
    my $delay = $reconnections[$self->{attempts}];
    $self->log($kernel, 'warning', "Attempting reconnection: $self->{attempts}, waiting: $delay seconds");
    $self->{attempts}++;
    $kernel->delay('reconnect', $delay);
  }
  else {
    if ($self->config('retry_reconnect')) {
      $self->log($kernel, 'warning', 'Cycling reconnection attempts, but not shutting down...');
      $self->{attempts} = 0;
      $kernel->yield('reconnect');
    }
    else {
      $self->log($kernel, 'warning', 'Shutting down, too many reconnection attempts');
      $kernel->yield('shutdown');
    }
  }
}


sub _soap_response {
  my ($kernel, $self, $resp, $pobj) = @_[ KERNEL, OBJECT, ARG0, ARG1];

  $self->log($kernel, 'debug', '_soap_response');

  my $error = undef;

  # error was probably because of a faulty SOAP call...
  if($self->{pocog_error}){
    $error = 'Faulty PoCo::Generic Object';
  }

  do{
    if ($pobj->{package} ne '') {
      eval {
        $pobj->result({
          session => $self->config('Alias'),
          event => '_soap_result',
          data => $resp->{factory},
        });
      };
      $error = $@ if $@;
    } else {
      $error = 'soap response has no package';
    }
  } unless $error;

  if ($error) {
    $self->log($kernel, 'warning',
               "_soap_response() exception in result(): $error");
    $kernel->yield('_handle_error', $error);
  }


}

sub _soap_result {
  my ($kernel, $self, $resp, $pobj) = @_[ KERNEL, OBJECT, ARG0, ARG1];

  $self->log($kernel, 'debug', '_soap_result');

  # return the object as returned by SOAP
  if (defined $pobj) {
    # pobj is the data, resp->{data} is the SOAP call name
    $kernel->yield('handle_result', [$resp->{data},$pobj]);
  } else {
    my $error = 'SOAP result returned invalid object';
    $self->log($kernel, 'warning',
               "_soap_result() exception in result(): $error");
    $kernel->yield('_handle_error', $error);
  }

}

sub AUTOLOAD {

  my $self = shift;

  our $AUTOLOAD;

  return undef if $self->{soap}->{fail};

  if ( $AUTOLOAD =~ m/::(\w+)$/ ) {
    unless($1 eq 'DESTROY' or $self->{please_wait}){
      eval q|$self->{soap}->{litex}->|.$1.q|(
                   {session => $self->config('Alias'), 
                    event => '_soap_response'}, @_)|;
      if ($@) {
        $self->log($poe_kernel, 'warning',
                   "exception in main autoload: $@");
        $poe_kernel->yield('_handle_error', $@);
      }

    }
  }
}


sub _handle_error {
  my ($kernel, $self, $error) = @_[KERNEL, OBJECT, ARG0];
  $self->{please_wait} = 1;
  $self->log($kernel, 'error', 'Error in service. Reset, and attempting to reconnect...');
  $kernel->post($self->config('Alias'), 'handle_error', ['-ERROR-', $error]);
  $self->{pocog_error} = undef;
  $self->_reconnect($kernel);
}

# ---------------------------------------------------------------------
# Public accessors
# ---------------------------------------------------------------------

sub config {
  my ($self, $arg) = @_;

  return $self->{CONFIG}->{$arg};

}


# ---------------------------------------------------------------------
# Public methods, these should be overridden, as needed
# ---------------------------------------------------------------------

sub log {
  my ($self, $kernel, $level, $message) = @_;
}

sub handle_result {
  my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];
}

sub handle_error {
  my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

}

sub handle_shutdown {
  my ($self, $kernel) = @_;

}

sub handle_connected {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

}


######################################################################
#                                                                    #
#              POE::Component::Client::SOAP::Nonblock                #
#                                                                    #
######################################################################
package POE::Component::Client::SOAP::Nonblock;

use warnings;
use strict;
our @EXPORT = ( );
use Switch;

use Carp qw(croak);
use POE;
use POE::Component::Generic;
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.01';

use SOAP::Lite;
use Devel::Symdump;

sub new {

  my $package = shift;
  my $params = shift;
  my $self = bless ({}, $package);

  my $soap = undef;

  eval{
    $soap = SOAP::Lite->new(
      proxy => $soap_config->{proxy},
      service => $soap_config->{service},
    );
  };

  return undef if $@ or !defined($soap);

  croak "Bad SOAP Service (non valid URI):".$soap->{_service}
    unless ($soap->{_service} =~ /^\w+\:\/\/\w+.*$/);


  # all methods from all services are mapped
  my @services = keys %{$soap->{_schema}->{_services}};
  my @soap_methods = ( );
  foreach my $service (@services) {
    foreach my $soap_method (keys %{$soap->{_schema}->{_services}->{$service}}) {
      push @soap_methods, $soap_method;
    }
  }

  # defined methods
  my $symdump = Devel::Symdump->new(qw(POE::Component::Client::SOAP::LiteX));
  my @defined_methods = $symdump->functions;

    # map all to the LiteX namespace
  foreach my $soap_method (@soap_methods) {
    unless($self->_find_symbol($soap_method, \@defined_methods)){
      eval q|
        sub POE::Component::Client::SOAP::LiteX::|.$soap_method.q| {
          my $self = shift;
          my $call = undef;
          eval {
            $call = $self->{soap_lite}->|.$soap_method.q|(@_);
          };
          if($@){
            warn $@;
            return undef;
          } else {
            return $call;
          }
        }|;
      warn "Error mapping SOAP method to LiteX: $@" if $@;
    }
  }


  # now PoCo::Generic thinks they are real ;-)
  $soap = POE::Component::Generic->spawn(
    alias => 'soapgeneric',
    package => 'POE::Component::Client::SOAP::LiteX',
    object_options => [
      proxy => $params->{proxy},
      service => $params->{service},
    ],
    factories => \@soap_methods,
    error => '_pocog_error',
    debug => $params->{debug}?$params->{debug}:0,
    verbose => $params->{verbose}?$params->{verbose}:0,
  );

  $self->{litex} = $soap?$soap:undef;
  return $soap?$self:undef;
}

sub _find_symbol {

  my ($self, $symbol, $where) = @_;
  foreach my $s (@$where) {
    $s =~ m/::(\w+)$/;
    return 1 if $symbol eq $1;
  }
  return 0;
}


######################################################################
#                                                                    #
#                 POE::Component::Client::SOAP::LiteX                #
#                                                                    #
######################################################################
package POE::Component::Client::SOAP::LiteX;

use warnings;
use strict;
our @EXPORT = ( );
use Carp qw(croak);
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.01';

use SOAP::Lite;

sub new {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my @args = @_;
  my $self = bless ({}, $package);
  my $soap_lite = SOAP::Lite->new(@args);
  return undef unless $soap_lite;
  $self->{soap_lite} = $soap_lite;
  return $self;
}


# Trap method not defined in the WSDL
sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  if ( $AUTOLOAD =~ m/::(\w+)$/ ) {
    unless($1 eq 'DESTROY'){
      warn "Sorry, cannot do: $1 in LiteX, since it's not defined in the WSDL.";
    }
  }
}


1;


__END__

=head1 NAME

POE::Component::Client::SOAP

=head1 SYNOPSIS

    # (1) Derive you own client class

    package My::SOAP;

    use base qw(POE::Component::Client::SOAP);

    sub spawn{

      my $package = shift;
      my $proxy = shift;
      my $service = shift;
      my $self = $class->SUPER::spawn(
           retry_reconnect => 1,
           proxy => $proxy,
           service => $service,
      );

      # initialized flag
      $self->{soc_stat} = 0;
      return $self;
    }

    # override connected method for status, for example
    sub handle_connected {
      my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

      # marks stomp client as initialized
      $self->{soc_stat} = 1;
    }

    # this must be overriden; it's the result from the call
    sub handle_result {
      my ($kernel, $self, $result) = @_[KERNEL,OBJECT,ARG0];
      # post to your session, or do whatever with SOAP result....
      $kernel->post($your_session, $call_back_event, $result);
      # result contains the SOAP call name and data
    }

    # usually overriden
    sub log {
      my ($self, $kernel, $level, $message) = @_;
    }

    sub handle_error {
      my ($kernel, $self, $result) = @_[KERNEL,OBJECT,ARG0];
      $self->{soc_stat} = 0;
      $kernel->post($your_session,$error_call_back_event, $result);
      # result contains the SOAP call name and error data
    }


    # (2) use it in the actual implementation

    use My::SOAP;

    my $soap = My::SOAP->spawn(
      proxy => 'http://your.soap.server',
      service = > 'http://your.soap.server/service.wsdl',
    )

    $soap->soapCall(params);

    ...

    sub call_back_event_handler{
      my ( $self, $kernel, $session, $soc_ret ) = @_[ OBJECT, KERNEL, SESSION, ARG0 ];
      $call  = $soc_ret->[0]; # which SOAP call is returning
      $data  = $soc_ret->[1]; # the data of the SOAP return
    }

=head1 DESCRIPTION

This module is a non-blocking wrapper around SOAP::Lite for POE. As
any non-blocking wrapper it needs to spawn a dedicated process to deal
with the blocking SOAP calls. As with most non-blocking wrappers we
used PoCo::Generic for abstracting all the details of the dedicated
process and it's events. Nevertheless, because we use PoCo::Generic,
it is mandatory to know all the SOAP methods beforehand, hence the
need to require a service descriptor (WSDL) to work with this library.

If you have a particular need to use SOAP WITHOUT WSDL, please drop a
line a we'll see what we can do to help you.

=head1 SEE ALSO

L<SOAP::Lite>

L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp>


L<POE::Component::Server::AsyncEndpoint>
L<POE>

=head1 AUTHOR

Alejandro Imass <ait@p2ee.org>
Alejandro Imass <aimass@corcaribe.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alejandro Imass / Corcaribe Tecnología C.A. for the P2EE Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


