package Net::ACME2::Challenge;

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge

=head1 DESCRIPTION

The ACME Challenge object.

(NB: The specification doesn’t seem to define this as a resource
per se .. oversight?)

Note that C<http-01> challenges use L<Net::ACME2::Challenge::http_01>.

=cut

use strict;
use warnings;

use parent qw( Net::ACME2::AccessorBase );

use Net::ACME2::X ();

use constant _ACCESSORS => (
    'url',
    'type',
    'status',
    'validated',
    'error',
    #'keyAuthorization',
);

=head1 ACCESSORS

These provide text strings as defined in the ACME specification.

=over

=item * B<url()>

=item * B<type()>

=item * B<token()>

=item * B<status()>

=item * B<validated()>

=back

=cut

1;
