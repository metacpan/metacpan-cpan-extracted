package Protocol::Database::PostgreSQL::Backend::ReadyForQuery;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::ReadyForQuery

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub state : method { shift->{state} }

sub new_from_message {
    my ($class, $msg) = @_;
    my (undef, undef, $state) = unpack('C1N1A1', $msg);
    $log->tracef("Backend state is %s", $state);
    return $class->new(
        state => $state
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

