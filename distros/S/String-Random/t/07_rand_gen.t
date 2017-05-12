use strict;
use warnings;

use Test::More tests => (6);

# 1: Make sure we can load the module
BEGIN { use_ok('String::Random'); }

# 2: Make sure we can create a new object with rand_gen argument
my $foo = String::Random->new(
    rand_gen => sub {
        my ($max) = @_;
        return int( $max - 1 );
    }
);
ok( defined($foo), "new()" );

# 3: Make sure _rand is defined
ok( defined( $foo->{'_rand'} ), "_rand defined" );

# 4: Make sure _rand returns value as expected
is( $foo->{'_rand'}(10), 9 )
    or diag "_rand function returned wrong value";

# 5: check randpattern with rand_gen function
my $cCn = $foo->randpattern("cCn");
is( $cCn, 'zZ9', "randpattern() with rand_gen" );

# 6: check randregex with rand_gen function
$cCn = $foo->randregex("[a-z][A-Z][0-9]");
is( $cCn, 'zZ9', "randregex() with rand_gen" );

# vi: set ai et syntax=perl:
