package RPC::Lite::Error;

use strict;
use base qw(RPC::Lite::Response);

=pod

=head1 NAME

RPC::Lite::Error -- An error response from an RPC::Lite::Server.

=head1 DESCRIPTION

RPC::Lite::Error derives from RPC::Lite::Response, but instead of
having a valid object in the Result field, it has error information
in the Error field.

=head1 METHODS

=over 4

=item C<new>

Takes the object to place in the Error field.

=cut

sub new
{
  my ($class, $data) = @_;

  my $self = bless {}, $class;
  $self->Error($data);

  return $self;
}

=pod

=item C<Result>

Returns undef on an RPC::Lite::Error object.

=cut

sub Result { return undef }

=pod

=item C<Error>

Returns the object encapsulated by the RPC::Lite::Error object.

=cut

sub Error  { $_[0]->{error} = $_[1] if @_>1; $_[0]->{error} }

=pod

=back

=head1 SEE ALSO

RPC::Lite::Response

=cut

1;
