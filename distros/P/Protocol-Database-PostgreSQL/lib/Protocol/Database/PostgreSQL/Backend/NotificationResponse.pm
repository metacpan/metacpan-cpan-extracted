package Protocol::Database::PostgreSQL::Backend::NotificationResponse;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::NotificationResponse

=head1 DESCRIPTION

=cut

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size, my $pid, my $channel, my $data) = unpack('C1N1N1Z*Z*', $msg);
    return $class->new(
        pid => $pid,
        channel => $channel,
        data => $data
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

