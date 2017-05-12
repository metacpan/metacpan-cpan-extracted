use 5.010;
use warnings;

use Test::More 'no_plan'; 

use List::Util qw< reduce >;

my $calculator = do{
    use Regexp::Grammars;
    qr{
        <Answer>

        <rule: Answer>
            <[Operand=Mult]> ** <[Op=(\+|\-)]>
                (?{ $MATCH = shift @{$MATCH{Operand}};
                    for my $term (@{$MATCH{Operand}}) {
                        my $op = shift @{$MATCH{Op}};
                        if ($op eq '+') { $MATCH += $term; }
                        else            { $MATCH -= $term; }
                    }
                })

        <rule: Mult>
            <[Operand=Pow]> ** <[Op=(\*|/|%)]>
                (?{ $MATCH = reduce { eval($a . shift(@{$MATCH{Op}}) . $b) }
                                    @{$MATCH{Operand}};
                })

        <rule: Pow>
            <[Operand=Term]> ** <Op=(\^)> 
                (?{ $MATCH = reduce { $b ** $a } reverse @{$MATCH{Operand}}; })

        <rule: Term>
               <MATCH=Literal>
          | \( <MATCH=Answer> \)

        <token: Literal>
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

while (my $input = <DATA>) {
    chomp $input;
    my ($expr, $result) = split /\s*=\s*/, $input;
    ok +($expr =~ $calculator) => "Matched expression: $expr";
    cmp_ok $/{Answer}, '==', $result => "Got right answer ($result)";
}

__DATA__
2^3*4+5   = 37
2+3*4^5   = 3074
2+3*4+5   = 19
2*3+4*5   = 26
2*(3+4)*5 = 70
2+3+4-5   = 4
100/10/2  = 5
100/10*2  = 20
