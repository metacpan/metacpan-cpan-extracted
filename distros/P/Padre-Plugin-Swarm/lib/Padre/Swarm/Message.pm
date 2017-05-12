package Padre::Swarm::Message;

use strict;
use warnings;
use Carp qw( croak );

# Provide a ->Dumper method
use Data::Dumper 'Dumper';

our $VERSION = '0.2';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub title {
	my $self = shift;
	$self->{title} = shift if @_;
	$self->{title};
}

sub body {
	my $self = shift;
	$self->{body} = shift if @_;
	$self->{body};
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	$self->{type};
}

sub to {
	my $self = shift;
	$self->{to} = shift if @_;
	$self->{to};
}

sub from {
	my $self = shift;
	$self->{from} = shift if @_;
	$self->{from};
}

sub service {
	my $self = shift;
	$self->{service} = shift if @_;
	$self->{service};
	
}

sub token {
    my $self = shift;
    $self->{token} = shift if @_;
    return $self->{token};
}

sub origin {
    my $self = shift;
    $self->{origin} = shift if @_;
    return $self->{origin};
}


sub TO_JSON {
	## really should be the canonical identity
	my $self = shift;
	my $ref = { %$self } ; # erm - better clone?
	my $msg = ref $self;
	unless ( $msg =~ s/^Padre::Swarm::Message:*// ) {
		croak "Not a swarm message!";
	}
	$ref->{__origin_class} = $msg if $msg;  # see Transport::_marshal
	$ref;
}

1;

__END__

=pod

=head1 NAME

Padre::Swarm::Message - A Swarm message base

=head1 SYNOPSIS

  my ($channel,$entity,$message) = $some_transport->receive_from( $some_channel );
  print $message->title , ' - ' , $message->type;
  if ( $message->type eq 'interesting' ) {
    # process 
  }  
  
  my $message = Padre::Swarm::Message->new( 
    title => 'Patch ./Changes',
    type  => 'svn:notify',
    from  => 'svn-jabber@example.com',
    to    => 'me@here.com',
    body  => $data ,
  );

=head1 DESCRIPTION

At transport layer, a  Swarm message has the attributes to, from,
title, body and type.

 title must be a string
 to and from must be L<Padre::Swarm::Identity> instances.
 type is always a string and may be used to subclass by registration
 subclasses must not mutate  title,type,from,to 
 body considered scalar bytes and entirely the problem of the 'type' implementor
  
=cut
