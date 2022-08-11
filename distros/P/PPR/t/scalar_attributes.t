use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require Attribute::Types }) {
        plan skip_all => "Attribute::Types required for this test";
        exit();
    }
}

use PPR;

package Foo { }
use Attribute::Types;
use feature qw(state);

my @cases = (
    q{my    Foo $my_count    :INTEGER = 12;},
    q{our   Foo $our_count   :INTEGER = 12;},
    q{state Foo $state_count :INTEGER = 12;},
);
plan tests => 0+@cases;

for my $case (@cases) {
    subtest "Case : << $case >>" => sub {
        ok eval "$case; 1", "valid code" or note "error: $@";
        ok $case =~ m{
            \A (?&PerlEntireDocument) \Z

            $PPR::GRAMMAR
        }x, 'PPR matches';
    };
}

done_testing();
