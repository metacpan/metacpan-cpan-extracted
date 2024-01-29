package Protocol::Database::PostgreSQL::Error;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

=head1 NAME

Protocol::Database::PostgreSQL::Error - represents a PostgreSQL error

=head1 DESCRIPTION

This inherits from L<Ryu::Exception> to provide a wrapper for exceptions and notices
raised by the server.

=cut

use parent qw(Ryu::Exception);

=head1 METHODS

=head2 code

The failing code.

=cut

sub code { shift->{code} }

=head2 file

Which PostgreSQL source file the error was raised from.

=cut

sub file { shift->{file} }

=head2 line

The line number in the PostgreSQL source file which raised this error.

=cut

sub line { shift->{line} }

=head2 message

The error message from the server.

=cut

sub message { shift->{message} }

=head2 position

The character offset in the input query.

=cut

sub position { shift->{position} }

=head2 routine

Which PostgreSQL processing routine raised this.

=cut

sub routine { shift->{routine} }

=head2 severity

Relative severity of the error, e.g. NOTICE or FATAL.

=cut

sub severity { shift->{severity} }

=head2 type

Look up the error information in tables extracted from PostgreSQL official documentation.
Returns a string corresponding to the error code, or C<unknown> if it's not in the tables
(or from a newer version than this module supports, currently 11.2).

=cut

sub type { $Protocol::Database::PostgreSQL::ERROR_CODE{shift->{code}} // 'unknown' }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

