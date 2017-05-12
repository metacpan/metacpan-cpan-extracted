package Net::Amazon::IAM::Error;
use Moose;

=head1 NAME

Net::Amazon::IAM::Error

=head1 DESCRIPTION

A class representing one or more errors from an API request.

=head1 ATTRIBUTES

=over

=item request_id (required)

The ID of the request associated with this error.

=item code (required)

Error code

=item message(required)

Error message

=cut

use overload '""' => 'as_string';

has 'code'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'message'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'request_id' => ( is => 'ro', isa => 'Str', required => 1 );

=back

=head2 as_string()

Format error as single string.

=over

Returns error as string.

=back

=cut

sub as_string {
  my $self = shift;
  return '['.$self->code.'] '.$self->message;
}

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <cpan@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2010 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
