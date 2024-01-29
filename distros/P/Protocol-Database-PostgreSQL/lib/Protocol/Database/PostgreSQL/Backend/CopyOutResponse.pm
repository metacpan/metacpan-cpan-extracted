package Protocol::Database::PostgreSQL::Backend::CopyOutResponse;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::CopyOutResponse

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub type { 'copy_out_response' }

sub data_format { shift->{data_format} }
sub count { shift->{count} }
sub new_from_message {
    my ($class, $msg) = @_;
    (undef, undef, my $data_format, my $count, my @formats) = unpack('C1N1C1n1 (n1)*', $msg);
    $log->tracef('COPY IN %s with %s columns, formats %s', $data_format, $count, \@formats);
    return $class->new(
        data_format => $data_format,
        count       => $count,
        formats     => \@formats
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

