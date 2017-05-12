package Net::SolarWinds::Result;

=head1 NAME

Net::SolarWinds::Result -  Result class

=head1 SYNOPSIS

  use Net::SolarWinds::Result;


  my $res=new_true Net::SolarWinds::Result('some data');

  print $res->get_data if($res);

  $res->set_false('some error');

  die $res unless $res;

=head1 DESCRIPTION

This package acts as a general result class, it allows for returing of state and objects within a single context using encapsulation.

=cut

use strict;
use warnings;

=head1 OVERLOADED METHODS

The following methods have been overloaded

  bool
    # an instance when set to false will test as false
  '""'
    # an instance when called in a string context will return
    # the error message given if any

=cut

use overload
  bool     => \&is_ok,
  '""'=>\&get_msg,
  fallback => 1;

=head1 OO Methods

=over 4

=item * Objec Construcotr(s)

Multiple objec constructors have been provided.

  new Net::SolarWinds::Result(
    bool=>0|1,
      # true false state
    data=>'string'|ref,
      # data for the $self->get_data command
    msg=>'human readable string',
      # message for the '""' op or $self->get_msg
    extra=>'string'|ref
      # extra paylod ( helpful in debugging )
  );

=cut 

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {%args}, $class;

    return $self;
}

=pod

  new_true Net::SolarWinds::Result($data,$extra)

   Returns a new true object

=cut

sub new_true {
    my ( $self, $data, $extra ) = @_;
    return $self->new( bool => 1, data => $data, extra => $extra );
}

=pod

  new_false Net::SolarWinds::Result($msg,$extra)

  Returns a new false instance

=cut

sub new_false {
    my ( $self, $msg, $extra ) = @_;
    return $self->new( bool => 0, msg => $msg, extra => $extra );
}

=pod
  
  new_error Net::SolarWinds::Result($msg,$extra);

  Returns a new false instance

=cut

sub new_error {
    my ( $self, $data, $extra ) = @_;
    return $self->new( bool => 1, data => $data, extra => $extra );
}

=pod

  new_ok Net::SolarWinds::Result($data,$extra);

  Returns a new true instance

=cut

sub new_ok {
    my ( $self, $data, $extra ) = @_;
    return $self->new( bool => 1, data => $data, extra => $extra );
}

=item * if($self->is_ok) {...}

Returns true if the instance is true.

=cut

sub is_ok {
    my ($self) = @_;
    return $self->{bool_cb}->() if exists $self->{bool_cb} and defined($self->{bool_cb}) and ref($self->{bool_cb}) and ref($self->{bool_cb}) eq 'CODE';
    return $self->{bool};
}

=item * my $data=$self->get_data

Returns the object from the data field

=cut

sub get_data {
    my ($self) = @_;

    # calls is_ok in a void context;
    $self->is_ok;
    return $self->{data};
}

=item * my $extra=$self->get_extra

Returns the object from the extra field

=cut

sub get_extra {
    my ($self) = @_;
    return $self->{extra};
}

=item * $self->set_true($data,$extra)

Sets the current argument to true, overloading the current $data and $extra objects

=cut

sub set_true {
    my ( $self, $data, $extra ) = @_;

    $self->{bool}  = 1;
    $self->{data}  = $data;
    $self->{msg}   = undef;
    $self->{extra} = $extra;
}

=item * my $error=$self->get_error

Returns the current msg value

=cut

sub get_error {
    my ($self) = @_;
    return $self->{msg};
}

=item * my $msg=$self->get_msg

Returns the current msg value, if undef it returns ''

=cut

sub get_msg {
    my ($self) = @_;

    return defined($self->{msg}) ?  $self->{msg} : '';
}

=item * $self->set_false($msg,$extra)

Sets the object to a false state, this will destroy an objects in the $data field.

=cut

sub set_false {
    my ( $self, $msg, $extra ) = @_;

    $self->{bool}  = 0;
    $self->{data}  = undef;
    $self->{msg}   = $msg;
    $self->{extra} = $extra;
}

=item * $self->set_boolean_cb(sub { 0 } );

Special case: allows for setting call backs for the boolean state.

=cut

sub set_boolean_cb {
  my ($self,$cb)=@_;
  delete $self->{bool_cb} unless defined($cb);
  $self->{bool_cb}=$cb;
}

=item * $self->DESTROY() 

Used for cleaning up the object internals

=cut

sub DESTROY {
  my ($self)=@_;
  return unless $self;
  delete @{$self}{qw(bool data bool_cb extra)};
}

=back

=head1 AUTHOR

Michael Shipper

=cut

1;
