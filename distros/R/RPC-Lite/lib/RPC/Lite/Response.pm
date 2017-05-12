package RPC::Lite::Response;

use strict;

=pod

=head1 NAME

RPC::Lite::Response -- Response object for RPC::Lite.

=head1 DESCRIPTION

RPC::Lite::Response encapsulates a response from an RPC::Lite::Server.  It is
the object that is serialized and returned over the transport layer.

=head1 METHODS

=over 4

=cut

=pod

=item C<new>

Takes the data to place into the Result field.

=cut

sub new
{
  my ( $class, $data ) = @_;

  my $self = bless {}, $class;
  $self->Result($data);

  return $self;
}

=pod

=item C<Result>

Returns the result (native object) of the request.

=cut

sub Result { $_[0]->{result} = $_[1] if @_ > 1; $_[0]->{result} }

=pod

=item C<Error>

Returns undef on a valid response.  Will only be filled in on RPC::Lite::Error
objects.

=cut

sub Error  { return undef }

=pod

=item C<Id>

The unique id of this response.  The id will match the id of the request that
generated the response.  This is used for handing asynchronous requests/responses.

=cut

sub Id     { $_[0]->{id}     = $_[1] if @_ > 1; $_[0]->{id} }

=pod

=back

=head1 SEE ALSO

RPC::Lite::Error

=cut

1;
