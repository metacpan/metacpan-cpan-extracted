package Net::SolarWinds::ConstructorHash;

use strict;
use warnings;
use base qw( Net::SolarWinds::LogMethods);

=pod

=head1 NAME

Net::SolarWinds::ConstructorHash - Default Hash object constructor

=head1 SYNOPSIS

  package MyClass;
  
  use base qw(Net::SolarWinds::ConstructorHash);
  
  1;
  
  my $pkg=new MyClass(key=>'value');

=head1 DESCRIPTION

This library provides a common base line construcotor that accepts an arbitrary key=>value pair set.


=head1 Setting default constructor values.

To create default constructor values, simply use the inherited OO constructor example:

  sub new {
  	my ($class,%args)=@_;
  	
  	return $class->SUPER::new(
  	  some_argument=>'default_value',
  	  %args
  	);
  }

=head1 OO Methods provided

=over 4

=item * Object constructor

This class provides a basic object constructor that accepts hash key value pairs as its arguments.  Keep in mind there are a few reserved hash keys.

Reserved hash keys:

  _shutdown=>0|1
    # wich is used to manage the shutdown state.

  log=>undef|Net::SolarWinds::Log instance
    # this key represents the log object ( if passed into the constructor as class->new(log=>Net::SolarWinds::Log->new()) )

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = bless { log => undef, _shutdown => 0, %args }, $class;

    return $self;
}

=item * $self->is_shutdown

This method should be used when running infinate loops to see if the application should stop running its extended loop.

=cut

sub is_shutdown { return $_[0]->{_shutdown} }

=item * $self->set_shutdown

Sets the object into the shutdown state.

=cut

sub set_shutdown { $_[0]->{_shutdown} = 1 }

=back

=head1 AUTHOR

Michael Shipper

=cut

1;
