package RPC::Lite::Request;

use strict;
use RPC::Lite::Notification;

=pod

=head1 NAME

RPC::Lite::Request -- encapsulates and RPC::Lite request.

=head1 DESCRIPTION

RPC::Lite::Request is the container for RPC::Lite requests.

=head1 METHODS

=over 4

=cut

=pod

=item C<new( $methodName, $parameterArrayReference )>

Creates a new RPC::Lite::Request object.  Takes the method name
and a reference to an array of parameters for the method.

=cut

sub new
{
  my ( $class, $method, $params ) = @_;

  my $self = bless {}, $class;

  $self->Method($method);
  $self->Params($params);

  return $self;
}

=pod

=item C<Method( [$methodName] )>

Sets/gets the method name.

=cut

sub Method     { $_[0]->{method}     = $_[1] if @_ > 1; $_[0]->{method} }

=pod

=item C<Params( [$parameterArrayReference] )>

Sets/gets the parameter array reference.

=cut

sub Params     { $_[0]->{params}     = $_[1] if @_ > 1; $_[0]->{params} }

=pod

=item C<Id( [$id] )>

Sets/gets the request id which is used for asynchronous calls.

=cut

sub Id         { $_[0]->{id}         = $_[1] if @_ > 1; $_[0]->{id} }

=pod

=back

=cut

1;
