package SysConfig;

require 5.005;
use strict;
use warnings;

our $VERSION = '0.2';
our $AUTOLOAD;

#####################################################################
# SysConfig.pm
# by Patrick Devine (c) 2001
# patrick@bubblehockey.org
#
# This software is covered under the same terms as Perl itself.
#
# WARNING:
#
# This software is no where near finished and lots of stuff will
# probably change before it is officially released (as 1.0).
#

#####################################################################
# method:	new
# function:	constructor method for creating an object

sub new {
  my $proto	= shift;
  my $class	= ref( $proto ) || $proto;
  my $self	= {};

  bless( $self, $class );

  $self;

}


#####################################################################
# method:	DESTROY
# function:	destructor method for object cleanup

sub DESTROY { };


#####################################################################
# method:	AUTOLOAD
# function:	autoload function for creating undefined methods

sub AUTOLOAD {
  my $self	= shift;
  my $params	= shift;

  my $name	= $AUTOLOAD;
  
  $name =~ s/ .* : //x;

  if( ref( $params ) eq 'HASH' ) {
    for( keys %{ $params } ) {

      my $prefix = substr( $_, 0, 1 );
      my $param = substr( $_, 1 );

      if( $prefix eq '-' ) {
        delete $self->{settings}->{$name}->{$param};
      } elsif( $prefix eq '+' ) {
        $self->{settings}->{$name}->{$param} = $$params{$_};
      } else {
        $self->{settings}->{$name}->{$_} = $$params{$_};
      }

    }
  } else {
    $self->{settings}->{$name} = { $name => $params };  
  }

}


#####################################################################
# method:	package
# function:	adds or removes packages

sub package {
  my $self	= shift;
  my $params	= shift;

  _set_hashofhash( $self, 'package', $params );

}


#####################################################################
# method:	partition
# function:	adds or removes partitions from the partition list

sub part {
  my $self	= shift;
  my $params	= shift;

  _set_listofhash( $self, 'dir', 'partition', $params );

}

sub partition {
  my $self	= shift;
  my $params	= shift;

  _set_listofhash( $self, 'dir', 'partition', $params );

}


#####################################################################
# method:	raid
# function:	adds or removes sw raid entries from the raid list

sub raid {
  my $self	= shift;
  my $params	= shift;

  _set_listofhash( $self, 'device', 'raid', $params );

}


#####################################################################
# method:	service
# function:	adds or removes service entries from the service list
#		(such as inetd and initd services)

sub service {
  my $self	= shift;
  my $params	= shift;

  _set_listofhash( $self, 'name', 'service', $params );

}


#####################################################################
# method:	device
# function:	add or remove an extra device for the device list
#		(useful for including devices which are not
#		 autodetected by the installer)

sub device {
  my $self	= shift;
  my $params	= shift;

  _set_listofhash( $self, 'module', 'device', $params );

}


#####################################################################
# method:	_set_hashofhash
# function:	turn settings inside of our hash on or off

sub _set_hashofhash {
  my $self	= shift;
  my $type	= shift;
  my $params	= shift;

  if( ref( $params ) eq 'ARRAY' ) {
    for( @{ $params } ) {

      my $prefix = substr( $_, 0, 1 );
      my $param = substr( $_, 1 );

      if( $prefix eq '-' ) {
	$self->{settings}->{$type}->{$param} = 'off';
      } elsif( $prefix eq '+' ) {
	$self->{settings}->{$type}->{$param} = 'on';
      } else {
	$self->{settings}->{$type}->{$_} = 'on';
      }

    }
  } else {
    my $prefix = substr( $params, 0, 1 );
    my $param = substr( $params, 1 );

    if( $prefix eq '-' ) {
      $self->{settings}->{$type}->{$param} = 'off';
    } elsif( $prefix eq '+' ) {
      $self->{settings}->{$type}->{$param} = 'on';
    } else {
      $self->{settings}->{$type}->{$params} = 'on';
    }
  } 

}

#####################################################################
# method:	_set_listofhash
# function:	turn settings inside of our list on or off

sub _set_listofhash {
  my $self	= shift;
  my $key	= shift;
  my $type	= shift;
  my $params	= shift;

  if( ref( $params ) eq 'HASH' ) {

    return unless exists $$params{$key};

    my $prefix = substr( $$params{$key}, 0, 1 );
    my $param = substr( $$params{$key}, 1 );

    if( $prefix eq '-' ) {
      my @list;
      for( @{ $self->{settings}->{$type} } ) {
        push( @list, $_ )
	  unless $_->{$key} eq $param;
      }
      @{ $self->{settings}->{$type} } = @list;
    } elsif( $prefix eq '+' ) {
      $$params{$key} = $param;
      push @{ $self->{settings}->{$type} }, $params;
    } else {
      push @{ $self->{settings}->{$type} }, $params;
    }
  }

}


1;

__END__

=pod
=head1 NAME

SysConfig - A base module for describing how to install a computer.

=head1 SYNOPSIS

This module is intended only as a base class.  You must use it in conjunction
with other classes such as SysConfig::Kickstart or SysConfig::XML in order to
make it do anything very useful.

=head1 DESCRIPTION


=head1 AUTHOR

Written by Patrick Devine (patrick@bubblehockey.org), (c) 2001.

=cut

