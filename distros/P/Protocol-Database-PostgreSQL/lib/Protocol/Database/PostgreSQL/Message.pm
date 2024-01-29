package Protocol::Database::PostgreSQL::Message;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

=head1 NAME

Protocol::Database::PostgreSQL::Message - base class for all message types

=head1 METHODS

Note that these are all defined in subclasses - this module just acts
as a common base to document the interface.

=head2 build

Constructs a message packet.

=head2 new_from_message

Parses a message packet (as a byte string) into an instance.

=cut

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

