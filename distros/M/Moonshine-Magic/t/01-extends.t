use Moonshine::Test qw/:all/;

package Test::Base;

use Moonshine::Magic;
use UNIVERSAL::Object;
extends 'UNIVERSAL::Object';

sub true {
    return 1;
}

sub false {
    return 0;
}

1;

package Test::One;

use Moonshine::Magic;

extends 'Test::Base';

package main;

my $instance = Test::One->new();

moon_test_one(
    test => 'true',
    instance => $instance,
    func => 'true',
);

moon_test_one(
    test => 'false',
    instance => $instance,
    func => 'false',
);

sunrise(2);
