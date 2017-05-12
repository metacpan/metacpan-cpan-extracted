#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use Switch::Plain;

my $var = 'foo';
sswitch ($var) {
    case 'foo': { is \$_, \$var; }
    default:    { fail "wtf? [$_]"; }
}

sswitch ('bar') {
    default: {
        eval { $_ = 'baz' };
        like $@, qr/^Modification of a read-only value attempted /;
    }
}
