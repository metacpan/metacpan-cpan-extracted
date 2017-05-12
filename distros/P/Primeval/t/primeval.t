use strict;
use warnings;
use Test::More tests => 10;

use Primeval;

$Primeval::RETURN = 1;

{
    my $x = 1;
    {
        my @y = (2, 3);
        {
            my %z = (4 => 5);
            my $str = prim{eval} '$x @y %z';
            like $str, qr'\$x: 1';
            like $str, qr'@y: \[2, 3\]';
            like $str, qr'%z: {4 => 5}';
        }
    }
}

{
    our $x = 1;
    {
        our @y = (2, 3);
        {
            our %z = (4 => 5);
            my @evals;
            my $str = prim{push @evals, $_; eval} qw($x @y %z);
            like $str, qr'\$x: 1';
            like $str, qr'@y: \[2, 3\]';
            like $str, qr'%z: {4 => 5}';
            is "@evals", '\$x \@y \%z';
        }
    }
}

SKIP: {
    skip 'perl 5.010+ required to test closures', 3
        if $] < 5.010;
    my $env = do {
        my $ex = 1;
        sub {
            my @ey = (2, 3);
            sub {
                my $x = $ex + @ey;
                my %ez = (4 => 5);
                my $str = prim{eval} '$ex @ey %ez';
                like $str, qr'\$ex: 1';
                like $str, qr'@ey: \[2, 3\]';
                like $str, qr'%ez: {4 => 5}';
            }
        }
    };

    $env->()->();
}
