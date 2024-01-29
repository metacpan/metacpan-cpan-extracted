package Protocol::Database::PostgreSQL::Backend::BackendKeyData;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::BackendKeyData - an authentication request message

=head1 DESCRIPTION

=cut

sub type { 'backend_key_data' }

sub pid { shift->{pid} }
sub key { shift->{key} }

sub new_from_message {
    my ($class, $msg) = @_;
    (undef, my $size, my $pid, my $key) = unpack('C1N1N1N1', $msg);
    return $class->new(
        pid => $pid,
        key => $key
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

