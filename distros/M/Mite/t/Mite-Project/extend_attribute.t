#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

tests "has +foo" => sub {
    mite_load <<'CODE';
package GP1;
use Mite::Shim;
has foo =>
    is      => 'ro',
    default => 23;

package P1;
use Mite::Shim;
extends 'GP1';

package C1;
use Mite::Shim;
extends 'P1';
has "+foo" =>
    default => "child default";

1;
CODE

    my $child = new_ok "C1";
    is $child->foo, "child default";
    throws_ok { $child->foo(23) }
              qr{(foo is a read-only attribute|Usage: C1::foo\(self\))};
};

done_testing;
