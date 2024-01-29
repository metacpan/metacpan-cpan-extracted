package Protocol::Database::PostgreSQL::Backend;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Message);

=head1 NAME

Protocol::Database::PostgreSQL::Backend - base class for all backend message types

=cut

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub type {
    my ($self) = @_;
    my ($type) = ref($self) =~ /([a-zA-Z]+)$/;
    return lcfirst($type) =~ s{([A-Z])}{'_' . lc($1)}ger;
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

