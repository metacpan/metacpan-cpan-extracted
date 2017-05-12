use strict;
$| = 1;

use POE 'Component::Schedule';

use Test::More tests => 6;

my $s;

# Check arg0: POE::Session
eval {
    $s = POE::Component::Schedule->add('none', 'tick', 3);
    is($s, undef, "no ticket created");
};

like($@, qr/^POE::Component::Schedule->add: first arg must be an existing POE session ID or alias/, "arg0 check");
is($s, undef, "no ticket created");


# Check arg2: DateTime::Set
for my $v (3, $poe_kernel) {
    $s = undef;
    eval {
        $s = POE::Component::Schedule->add($poe_kernel, 'tick', 3);
    };

    like($@, qr/^POE::Component::Schedule->add: third arg must be a DateTime::Set /, "arg2 check");
    is($s, undef, "no ticket created");
}
