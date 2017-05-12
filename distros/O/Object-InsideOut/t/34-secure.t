use strict;
use warnings;

BEGIN {
    eval { require Math::Random::MT::Auto; };
    if ($@) {
        print("1..0 # Skip Math::Random::MT::Auto not available\n");
        exit(0);
    }
    if ($Math::Random::MT::Auto::VERSION < 5.04) {
        print("1..0 # Skip Needs Math::Random::MT::Auto v5.04 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 4;

package Foo; {
    use Object::InsideOut ':SECURE';

    my %data :Field :All(data);
}

package Bar; {
    use Object::InsideOut qw(Foo);

    my %info :Field :All(info);
    #my @foo :Field;
}

package main;

my $obj = Bar->new('data' => 1, 'info' => 2);
is($obj->data(), 1, 'Get data');
is($obj->info(), 2, 'Get info');

eval { Bar->create_field('@misc', ':Field', ':All(misc)'); };
like($@->error, qr/Can't combine 'hash only'/, 'Hash only');
#print($@);

ok($$obj != 1, "ID: $$obj");

exit(0);

# EOF
