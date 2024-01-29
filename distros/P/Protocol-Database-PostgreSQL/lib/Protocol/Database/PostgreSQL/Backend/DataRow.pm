package Protocol::Database::PostgreSQL::Backend::DataRow;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::DataRow

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub type { 'data_row' }

sub fields { shift->{fields}->@* }

sub new_from_message {
    my ($class, $msg) = @_;
    my (undef, undef, $count) = unpack('C1N1n1', $msg);
    substr $msg, 0, 7, '';
    my @fields;
    foreach my $idx (0..$count - 1) {
        my ($size) = unpack('N1', substr $msg, 0, 4, '');
        if($size == 0xFFFFFFFF) {
            push @fields, undef;
        } else {
            push @fields, substr $msg, 0, $size, '';
        }
    }
    return $class->new(
        fields => \@fields
    )
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

