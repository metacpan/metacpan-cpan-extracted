use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

BEGIN {
    $Math::Random::MT::Auto::shared = 1;
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

if ($] == 5.008) {
    require 't/test.pl';   # Test::More work-alike for Perl 5.8.0
} else {
    require Test::More;
}
Test::More->import();
plan('tests' => 10);


package Foo; {
    use Object::InsideOut ':SECURE :SHARED';

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

ok($$obj != 1, "ID: $$obj");

threads->create(sub {
    my $id = shift;
    is($$obj, $id, 'Same ID in thread');
    is($obj->data(), 1, 'Get data in thread');
    is($obj->info(), 2, 'Get info in thread');

    my $obj2 = Bar->new('data' => 5, 'info' => 9);
    ok($$obj2 != 1, "ID: $$obj2");
    is($obj2->data(), 5, 'Get data in thread');
    is($obj2->info(), 9, 'Get info in thread');

}, $$obj)->join();

exit(0);

# EOF
