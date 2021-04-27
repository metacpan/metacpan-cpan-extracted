package Myriad::Exception::Base;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

no indirect qw(fatal);
use utf8;

=encoding utf8

=head1 NAME

Myriad::Exception::Base - common class for all exceptions

=head1 DESCRIPTION

See L<Myriad::Exception> for the rôle which defines the exception API.

=cut

use Myriad::Exception;

use overload '""' => sub { shift->as_string }, bool => sub { 1 }, fallback => 1;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

=head2 reason

The failure reason. Freeform text.

=cut

sub reason { shift->{reason} }

=head2 as_string

Returns the exception message as a string.

=cut

sub as_string { shift->message }

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

