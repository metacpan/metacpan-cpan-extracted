use strict;
use warnings;

require t::lib::Numeros;


use Number::Phone;
use Number::Phone::FR ':full';

use Test::More;
use Test::NoWarnings;

my @operators = keys %Numeros::operators;

plan tests => scalar @operators + 1;

foreach my $op (@operators) {
    subtest "Operateur $op", sub {
        plan tests => scalar @{ $Numeros::operators{$op} };
        foreach my $num (@{ $Numeros::operators{$op} }) {
            subtest "Numero $num", sub {
                plan tests => 2;
                my $n = Number::Phone::FR->new($num);
                isa_ok($n, 'Number::Phone::FR::Full', "Test $num");
                SKIP: {
                    skip "is_valid failed", 1 unless defined $n;

                    TODO: {
                        local $TODO = "Implement ->operator";
                        diag "Subscriber: ".$n->subscriber;
                        is($n->operator, $op, "Test $num -> $op");
                    }
                }
            }
        }
    }
}

