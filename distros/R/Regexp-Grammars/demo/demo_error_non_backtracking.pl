use v5.10;
use warnings;

use List::Util qw< reduce >;

my $calculator = do{
    use Regexp::Grammars;
    qr{ 
        \A 
        <Answer>
        (*COMMIT)   # <-- Remove this to see the error messages get less accurate
        (?:
            \Z
        |
            <warning: (?{ "Extra junk after expression at index $INDEX: '$CONTEXT'" })>
            <warning: Expected end of input>
            <error:>
        )

        <rule: Answer>  
            <[_Operand=Mult]>+ % <[_Op=(\+|\-)]>
                (?{ $MATCH = shift @{$MATCH{_Operand}};
                    for my $term (@{$MATCH{_Operand}}) {
                        my $op = shift @{$MATCH{_Op}};
                        if ($op eq '+') { $MATCH += $term; }
                        else            { $MATCH -= $term; }
                    }
                })
          |
            <error: Expected valid arithmetic expression>

        <rule: Mult> 
        (?:
            <[_Operand=Pow]>+ % <[_Op=(\*|/|%)]>
                (?{ $MATCH = reduce { eval($a . shift(@{$MATCH{_Op}}) . $b) }
                                    @{$MATCH{_Operand}};
                })
        )

        <rule: Pow> 
        (?:
            <[_Operand=Term]>+ % <_Op=(\^)> 
                (?{ $MATCH = reduce { $b ** $a } reverse @{$MATCH{_Operand}}; })
        )

        <rule: Term>
        (?:
               <MATCH=Literal>
          | \( <MATCH=Answer> \)
        )

        <token: Literal>
        (?:
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
        |
            <error:>
        )

    }xms
};

#open my $fh, '>', "source_$$";
#say $calculator; die;

while (my $input = <>) {
    if ($input =~ $calculator) {
        say '--> ', $/{Answer};
    }
    say {*STDERR} $_ for  @!;

}
