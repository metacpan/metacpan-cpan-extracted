package Protocol::Database::PostgreSQL::Backend::CopyInResponse;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::CopyInResponse

=head1 DESCRIPTION

=cut

sub type { 'copy_in_response' }

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, undef, my $type, my $count) = unpack('C1N1C1n1', $msg);
    substr $msg, 0, 8, '';
    my @formats;
    for (1..$count) {
        push @formats, unpack('n1', $msg);
        substr $msg, 0, 2, '';
    }
    return $class->new(
        formats => \@formats
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

