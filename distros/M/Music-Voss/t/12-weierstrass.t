#!perl

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::Voss;

can_ok( 'Music::Voss', qw(weierstrass) );

my $fun = Music::Voss::weierstrass( r => 0.5, H => 1.0, N => 32 );

# same (bad?) numbers as the LISP implementation, at least
my @seq;
for my $t ( 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6 ) {
    push @seq, $fun->($t);
}
$deeply->(
    [ map { sprintf "%.3f", $_ } @seq ],
    [qw/0.000 0.852 1.086 1.262 0.996 1.000 0.906/]
);

my @cb_args;
$fun = Music::Voss::weierstrass(
    r     => 0.5,
    H     => 1.0,
    N     => 32,
    phase => sub {
        my ( $t, $x, $k, %params ) = @_;
        @cb_args = ( $t, $x, $k, $params{r}, $params{H}, $params{N} );
        return 0;
    }
);
$fun->( 42, 640 );
$deeply->( \@cb_args, [ 42, 640, 32, 0.5, 1.0, 32 ] );

plan tests => 3;
