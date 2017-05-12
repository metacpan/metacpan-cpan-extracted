use v5.10;
use warnings;

use List::Util qw< reduce >;

my $calculator = do{
    use Regexp::Grammars;
    qr{
        \A
        <Answer>

        <rule: Answer>
            <[_Operand=Mult]>+ % <[_Op=(\+|\-)]>
                (?{ $MATCH = shift @{$MATCH{_Operand}};
                    for my $term (@{$MATCH{_Operand}}) {
                        my $op = shift @{$MATCH{_Op}//=[]};
                        if ($op eq '+') { $MATCH += $term; }
                        else            { $MATCH -= $term; }
                    }
                })

        <rule: Mult>
            <[_Operand=Pow]>+ % <[_Op=(\*|/|%)]>
                (?{ $MATCH = reduce { eval($a . shift(@{$MATCH{_Op}}) . $b) }
                                    @{$MATCH{_Operand}};
                })

        <rule: Pow>
            <[_Operand=Term]>+ % <_Op=(\^)> 
                (?{ $MATCH = reduce { $b ** $a } reverse @{$MATCH{_Operand}}; })

        <rule: Term>
               <MATCH=Literal>
          | <.OpenParen= (\() >
            <MATCH=Answer>
            <.CloseParen= (\)) >

        <token: Literal>
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

#say $calculator; die;

while (my $input = <>) {
    if ($input =~ $calculator) {
        say '--> ', $/{Answer};
    }
}

