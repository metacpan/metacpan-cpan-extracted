package Padre::Swarm::Identity;

=pod

=head1 NAME

Padre::Swarm::Identity - represent a unique identity in the swarm

=head1 SYNOPSIS

  my $id = $message->identity;
  printf(
      '%s @[%s] using resource %s on service %s',
      $id->nickname,
      $id->transport,
      $id->resource,
      $id->service,
  );
  my $swarm_id = $id->canonical;

=head1 DESCRIPTION

Attempt to make anything and everything addressable. More work needed.

=cut

use strict;
use warnings;
use Carp         qw( croak );
use Params::Util qw( _STRING );

use Class::XSAccessor 
	constructor => 'new',
	getters     => {
		nickname  => 'nickname',
		transport => 'transport',
		service   => 'service',
		resource  => 'resource',
		identity  => 'identity',
	};

sub is_valid {
	defined $_[0]->{canonical};
}

sub set_nickname {
	my $self = shift;
	my $arg  = shift;
	my ($nickname) = $arg =~ /([^\W!]+)/;
	croak "Invalid nickname '$arg'" unless $nickname;
	$self->{nickname} = $nickname;
}

sub set_service  {
	my ($self,$xport) = @_;
	$self->{service} = $xport;
}


sub set_transport {
	my ($self,$xport) = @_;
	$self->{transport} = $xport;
}

sub set_resource {
	my ($self,$xport) = @_;
	$self->{resource} = $xport;
}

sub canonical { 
	my $self = shift;
	$self->_canonise;
}

sub _canonise {
	my $self  = shift;
	# Revolting!
	my $ident = sprintf(
		'%s!%s|%s@%s' ,
		$self->{nickname},
		$self->{service},
		$self->{transport} || 'unknown',
		$self->{resource}  || '',
	);
	$self->{canonical} = $ident;
}

1;
