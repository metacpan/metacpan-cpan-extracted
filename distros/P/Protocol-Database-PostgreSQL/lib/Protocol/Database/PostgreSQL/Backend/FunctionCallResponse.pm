package Protocol::Database::PostgreSQL::Backend::FunctionCallResponse;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::FunctionCallResponse

=head1 DESCRIPTION

=cut

sub type { 'function_call_response' }

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size, my $len) = unpack('C1N1N1', $msg);
    substr $msg, 0, 9, '';
    my $data = ($len == 0xFFFFFFFF) ? undef : substr $msg, 0, $len;
    return $class->new(
        data => $data,
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

