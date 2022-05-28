package My::Point;
use MooseX::Extended types => [qw/Num HashRef/];

param [ 'x', 'y' ] => ( isa => Num );
field session => ( isa => HashRef, init_arg => undef, default => sub { { session => 1234 } } );

sub session_id ($self) {
    my $session = $self->session;
    return "$session->@{session}";
}

package My::Point::Mutable;
use MooseX::Extended;
extends 'My::Point';

param [ '+x', '+y' ] => ( writer => 1, clearer => 1, default => 0 );

sub invert ($self) {
    my ( $x, $y ) = ( $self->x, $self->y );
    $self->set_x($y);
    $self->set_y($x);
}

# MooseX::Extended will causet this to return true, even if we try to return
# false
0;
