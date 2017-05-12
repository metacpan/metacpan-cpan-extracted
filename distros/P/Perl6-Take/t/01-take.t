#!perl -Tw

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Perl6::Take;

{
    my @take;
    my $en_passant;
    my @en_passant;

    @take = gather { 42 };
    is @take, 0, "no spurious takes";
    diag "took: [@take]" if @take;

    @take = gather { take 42 };
    is "@take", "42", "simple gather with scalar take";

    @take = gather { ($en_passant) = take 42 };
    is "@take", "42", "simple gather with scalar take and en passant scalar assignment";
    is $en_passant, 42, "en passant taken value";

    $_ = 54;
    dies_ok { @take = gather { take } } "no gather with \$_ take";

    @take = gather { take 42; take 54 };
    is "@take", "42 54", "two takes";

    @take = gather { take 42, 54 };
    is "@take", "42 54", "take list";

    @take = gather { take 1, 2; @en_passant = take 42, 54; take 3, 4 };
    is "@take", "1 2 42 54 3 4", "list en passant assignment";
    is "@en_passant", "42 54", "take en passant";
}

{
    local $TODO = "can't yet trap a return()";
    throws_ok { my @foo = gather { return "bar" } }
            qr/unimplemented.*return/, "return disallowed inside gather block";
}

{
    my (@outer, @inner1, @inner2);
    @outer = gather {
        take 1;
        take 2, 3;
        @inner1 = gather {
            take "A";
            take qw/B C/;
        };
        @inner2 =  gather {
            take "Alpha";
            take qw/Beta Gamma/;
        };
    };
    is "@outer",  "1 2 3",            "outer scope";
    is "@inner1", "A B C",            "first inner scope";
    is "@inner2", "Alpha Beta Gamma", "second inner scope";
}

{
    my @other;

    sub dyn1 {
        take $_[0] + 1;
    }
    sub dyn2 {
        take $_[0] - 1;
    }

    sub dyn3 {
        @other = gather { take 5 };
        dyn1(@_);
    }

    my @take = gather {
        dyn1(0);
        dyn2(0);
        for my $n (1 .. 3) {
            dyn3($n);
        }
    };

    is "@take",  "1 -1 2 3 4", "dynamically scoped takes";
    is "@other", "5",          "not distracted by nested gathers";

    throws_ok { take 5 } qr/take with no gather/,
              "take with no gather throws exception";
}
