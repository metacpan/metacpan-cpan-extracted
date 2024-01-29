package Protocol::Database::PostgreSQL::Backend::CommandComplete;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::CommandComplete - an authentication request message

=head1 DESCRIPTION

=cut

sub type { 'command_complete' }

sub result { shift->{result} }

sub new_from_message {
    my ($class, $msg) = @_;
    my (undef, undef, $result) = unpack('C1N1Z*', $msg);
    return $class->new(
        result => $result
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

