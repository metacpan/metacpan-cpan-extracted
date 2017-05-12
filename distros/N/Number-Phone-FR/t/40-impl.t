use strict;
use warnings;

use lib 't/lib';
use Numeros;

use Test::More tests => 5 + 1;
use Test::NoWarnings;

my @numeros = @Numeros::intl;

use Number::Phone;

sub impl_test
{
    my $class = shift;
    my $pkg = (caller)[0];
    subtest "Package $pkg => $class", sub {
        plan tests => 3;
        my $num = Number::Phone->new($numeros[0]);
        isa_ok($num, 'Number::Phone::FR');
        isa_ok($num, $class);
        is(ref $num, $class, $class);
    };
}

impl_test 'Number::Phone::FR';

{
    package Foo;
    use Number::Phone::FR ':full';

    main::impl_test 'Number::Phone::FR::Full';
}

impl_test 'Number::Phone::FR';

{
    package Bar;
    use Number::Phone::FR ':simple';

    main::impl_test 'Number::Phone::FR::Simple';
}

impl_test 'Number::Phone::FR';


