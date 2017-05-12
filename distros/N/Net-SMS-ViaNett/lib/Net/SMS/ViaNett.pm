package Net::SMS::ViaNett;

=head1 NAME

Net::SMS::ViaNett  -  Perl Interface to Vianett HTTP API

=cut

use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed reftype/;
use LWP::UserAgent;
use XML::Simple;
use Data::URIEncode;

use constant VIANETT_URL => 'http://smsc.vianett.no/ActiveServer/MT/';

our $VERSION = q(0.02);

sub _validate {
  shift;

  my $args      = shift;
  my $transform = { };

  my $allowed = {
    to => {
      translate   => 'destinationaddr',
      required    => 1,
      default     => undef,
    },
  
    from => {
      translate   => 'sourceaddr',
      required    => 1,
      default     => sub { int( rand( 9999 ) ) }
    },

    msg => {
      translate   => 'message',
      required    => 1,
      default     => undef
    },
   
    refno => {
      translate   => 'refno',
      required    => 1,
      default     => sub { int( rand( 999999 ) ) }
    },

    origin => {
      translate   => 'fromalpha',
      required    => 0,
      default     => undef
    },

    header => {
      translate   => 'messageheader',
      required    => 0,
      default     => undef
    },

    operator => {
      translate   => 'operator',
      required    => 0,
      default     => 0
    },
   
    pricegroup => {
      translate   => 'pricegroup',
      required    => 0,
      default     => 0
    }
  };

  foreach my $k ( keys %$allowed ) {

    __PACKAGE__->_error( "$k is a required parameter" ) 
      if( 
        $allowed->{$k}->{required}             &&     # A Required Key
        ! defined( $allowed->{$k}->{default} ) &&     # With no defaults Given
        ! exists( $args->{$k} )                       # Must Exist in the parameters
      );


      if( exists( $args->{$k} ) && defined( $args->{$k} ) ) {
        $transform->{ $allowed->{$k}->{translate} }  = $args->{$k};
      } elsif( $allowed->{$k}->{required} && ! exists( $args->{$k} ) ) {
        if( reftype $allowed->{$k}->{default} eq 'CODE' ) {
          $transform->{ $allowed->{$k}->{translate} } = &{$allowed->{$k}->{default}}();
        } else { 
          $transform->{ $allowed->{$k}->{translate} } = $allowed->{$k}->{default};
        }
      }
  }

  return $transform;
};



sub new {
  my $class = shift;
  my %args  = @_;
  
  __PACKAGE__->_error("Can't call from instantiated object") if blessed $class;
  __PACKAGE__->_error("Can't call as static method") unless( $class->isa( __PACKAGE__ ) );
  __PACKAGE__->_error("Invalid arguments passed to the constructor") 
    unless( %args && ( defined $args{username} && defined $args{password} ) );

  my $this = { %args };

  return bless $this, $class;
}


sub agent {
  my ( $this, $agent ) = @_;

  __PACKAGE__->error( "Cant call as static method" ) unless blessed $this;

  return ( $this->{_agent} || __PACKAGE__ . '/' . $VERSION ) unless $agent;

  $this->{_agent} = $agent;
}


sub _to_url {
  my ( $this, $params ) = @_;

  __PACKAGE__->error( "Cant call as static method" ) unless blessed $this;

  # username and password
  @{$params}{qw/username password/} = ( $this->{username}, $this->{password} );

  return VIANETT_URL . '?' . Data::URIEncode::complex_to_query( $params )
}


sub send {
  my $this = shift;

  __PACKAGE__->_error( "Cant call as static method" ) unless blessed $this;

  my %args      = @_;
  my $response  = $this->_call( $this->_to_url( $this->_validate( { %args } ) ) );

  return $response->{errorcode} == 0 ? 1 : 0;
}



sub _call {
  my $this = shift;

  __PACKAGE__->_error( "Cant call as static method" ) unless blessed $this;

  my ( $url, $ua, $response ) = ( shift, LWP::UserAgent->new,  );
  $ua->agent( $this->agent );
  $response = $ua->get( $url );

  __PACKAGE__->_error( "Error Making the request, server responded with " . $response->status_line )
    if $response->is_error;

  return XML::Simple::XMLin( $response->content );

}


sub _error {
  shift;
  confess shift;
}



1;
__END__


=head1 SYNOPSIS

    use Net::SMS::ViaNett;


    my $obj = Net::SMS::ViaNett->new( username => $username, password => $password );
    if( $obj->send( to => $phone, msg => $message ) ) {
      print "Sent";
    } else {
      print "Not Sent";
    }

=head1 DESCRIPTION


Vianett ( http://www.vianett.com ) offers commercial service for sending / recieving SMS
amongst other services. This module offers a convinient way to send SMS using ViaNett's 
API.

ViaNett offers various ways to contact their API, this module uses their HTTP API.

ViaNett's API documentation can be found at http://sms.vianett.com/cat/29.aspx

Please take note that neither this software nor the author are related to ViaNett in any way.


=head1 METHODS

=over 3

=item new

Creates the Net::SMS::ViaNett Object

Usage:

  my $vianett = Net::SMS::ViaNett->new( username => $username, password => $password );

The complete list of arguments is:

  username  : The username that is given by Vianett
  password  : The password that is given by Vianett

=item agent

Sets/Gets User-Agent String to be sent to ViaNett during the HTTP Request

Usage:

  # Gets Current User-Agent String 
  $vianett->agent;   

  # Sets User-Agent String
  $vianett->agent( 'Spider Monkey' );


=item send

Sends the message through ViaNett's API

Usage:

    $vianett->send( to => $number, msg => $message );

    $vianett->send( to => $number, msg => $message, from => $source );

send method accepts following arguments

    to          - Destination number
    from        - Originator number 
    msg         - The message you want to send
    origin      - Alpha numeric originator number. Can only be used with messages with pricegroup=0
    operator    - The operator ID. Use 0 if this number is unknown.
    refno       - Message reference number. This number must be a unique ID.
    pricegroup  - The pricegroup. Example: 100 is NOK 1,- and 1500 is NOK 15,-.
    header      - The Optional Message Header

return 1 on success and 0 on failure

=back 

=head1 AUTHOR

Venkatakrishnan Ganesh <gvenkat@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009 Venkatakrishnan Ganesh. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This software or the author aren't related to ViaNett in any way.

=cut






