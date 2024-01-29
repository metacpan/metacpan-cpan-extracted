package Protocol::Database::PostgreSQL::Backend::NoticeResponse;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::NoticeResponse

=head1 DESCRIPTION

=cut

sub type { 'notice_response' }

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size) = unpack('C1N1', $msg);
    substr $msg, 0, 5, '';
    my %notice;
    FIELD:
    while(length($msg)) {
        my ($code, $str) = unpack('A1Z*', $msg);
        last FIELD unless $code && $code ne "\0";

        die "Unknown NOTICE code [$code]" unless exists $Protocol::Database::PostgreSQL::NOTICE_CODE{$code};
        $notice{$Protocol::Database::PostgreSQL::NOTICE_CODE{$code}} = $str;
        substr $msg, 0, 2+length($str), '';
    }
    return $class->new(
        %notice
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

