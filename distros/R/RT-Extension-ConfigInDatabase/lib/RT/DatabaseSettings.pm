use strict;
use warnings;

package RT::DatabaseSettings;
use base 'RT::SearchBuilder';

=head1 NAME

RT::DatabaseSettings - a collection of L<RT::DatabaseSettings> objects

=cut

sub NewItem {
    my $self = shift;
    return RT::DatabaseSetting->new( $self->CurrentUser );
}

=head2 _Init

Sets default ordering by id ascending.

=cut

sub _Init {
    my $self = shift;

    $self->{'with_disabled_column'} = 1;

    $self->OrderBy( FIELD => 'id', ORDER => 'ASC' );
    return $self->SUPER::_Init( @_ );
}

sub Table { "RTxDatabaseSettings" }

1;


