package Protocol::Database::PostgreSQL::Backend::ParameterDescription;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::ParameterDescription

=head1 DESCRIPTION

=cut

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size, my $count) = unpack('C1N1n1', $msg);
    substr $msg, 0, 7, '';
    my @oid_list;
    for my $idx (1..$count) {
        my ($oid) = unpack('N1', $msg);
        substr $msg, 0, 4, '';
        push @oid_list, $oid;
    }
    return $class->new(
        oids => \@oid_list
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

