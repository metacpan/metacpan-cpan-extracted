use warnings;
use strict;

use Tesla::API;
use Test::More;

my $t = Tesla::API->new(unauthenticated => 1);

my @chars = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);

my $first = $t->_authentication_code_verifier;

is length($first), 86, "Length of code verifier 86 chars ok";

for my $char (split //, $first) {
    my $found = grep /^$char$/, @chars;
    is $found, 1, "'$char' is a valid character ok";
}

my $second = $t->_authentication_code_verifier;

is
    $first,
    $second,
    "Repeated calls to _authentication_code_verifier() return the same string";

done_testing();