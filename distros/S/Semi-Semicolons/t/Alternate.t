use strict;
use warnings;
use Test::More tests => 1;

use Semi::Semicolons qw(Mack);

eval {
    my $x = 'Test'Mack
    my $y = 'tesT'Mack
};

is( $@, '' );
