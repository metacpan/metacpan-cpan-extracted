use strict;
use warnings;

package RT::AuthTokens;
use base 'RT::SearchBuilder';

=head1 NAME

RT::AuthTokens - a collection of L<RT::AuthToken> objects

=cut

=head2 LimitOwner

Limit Owner

=cut

sub LimitOwner {
    my $self = shift;
    my %args = (
        FIELD    => 'Owner',
        OPERATOR => '=',
        @_
    );

    $self->SUPER::Limit(%args);
}

sub NewItem {
    my $self = shift;
    return RT::AuthToken->new( $self->CurrentUser );
}

=head2 _Init

Sets default ordering by id ascending.

=cut

sub _Init {
    my $self = shift;

    $self->OrderBy( FIELD => 'id', ORDER => 'ASC' );
    return $self->SUPER::_Init( @_ );
}

sub Table { "RTxAuthTokens" }

1;

