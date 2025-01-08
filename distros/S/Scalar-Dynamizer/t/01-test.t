use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Dynamizer qw(dynamize);

my $count = 0;

sub get_username {
    return "fakeuser";
}

my $dynamized = dynamize {
    return $count++;
};

my $user = dynamize {
    return get_username();
};

ok(!$dynamized, "dynamized boolean evaluates false");
ok($dynamized, "dynamized boolean evaluates true");
is($dynamized, 2, "dynamized numeric value increments correctly");
is($dynamized * 100, 300, "dynamized numeric value maths correctly");
is("Count: $dynamized", "Count: 4", "dynamized string interpolates correctly");
is($user, "fakeuser", "dynamized string overload works correctly");

done_testing();
