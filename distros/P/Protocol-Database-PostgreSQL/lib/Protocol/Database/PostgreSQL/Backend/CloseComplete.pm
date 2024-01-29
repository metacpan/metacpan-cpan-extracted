package Protocol::Database::PostgreSQL::Backend::CloseComplete;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::CloseComplete - an authentication request message

=head1 DESCRIPTION

=cut

sub type { 'close_complete' }

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size) = unpack('C1N1', $msg);

    return $class->new;
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

