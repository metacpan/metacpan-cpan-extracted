use 5.010;
use warnings;
use Test::More 'no_plan';

use List::Util qw< reduce >;

sub translator {
    my ($errormsg, $rulename, $context) = @_;

    if (substr($rulename,0,1) eq '-') {
        $rulename = substr($rulename,1);
        return "You forgot to define $rulename. :-(";
    }

    if ($errormsg eq q{}) {
        if ($rulename) {
            return "<$rulename> failed to match '$context'";
        }
        else {
            return "Main pattern failed to match '$context'";
        }
    }

    if (lc(substr($errormsg,0,6)) eq 'wanted') {
        return "$errormsg, but was given '$context'. What's up with that?";
    }

    return $errormsg;
}

my $calculator = do{
    use Regexp::Grammars;

    qr{ 
        \A 
        <Answer>
        (?:
            \Z
        |
            <warning: (?{ "Extra junk after expression at index $INDEX: '$CONTEXT'" })>
            <warning: Wanted end of input>
            <error:>
        )

        <rule: Answer>  
            <[_Operand=Mult]> ** <[_Op=(\+|\-)]>
                (?{ $MATCH = shift @{$MATCH{_Operand}};
                    for my $term (@{$MATCH{_Operand}}) {
                        my $op = shift @{$MATCH{_Op}};
                        if ($op eq '+') { $MATCH += $term; }
                        else            { $MATCH -= $term; }
                    }
                })
          |
            <Trailing_stuff>

        <rule: Mult> 
        (?:
            <[_Operand=Pow]> ** <[_Op=(\*|/|%)]>
                (?{ $MATCH = reduce { eval($a . shift(@{$MATCH{_Op}}) . $b) }
                                    @{$MATCH{_Operand}};
                })
        )

        <rule: Pow> 
        (?:
            <[_Operand=Term]> ** <_Op=(\^)> 
                (?{ $MATCH = reduce { $b ** $a } reverse @{$MATCH{_Operand}}; })
        )

        <rule: Term>
        (?:
               <MATCH=Literal>
          | \( <MATCH=Answer> \)
        )

        <rule: Trailing_stuff>
            <...>

        <token: Literal>
            <error:>
        |
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>

    }xms
};

local $/ = "";
{
    my $temp = Regexp::Grammars::set_error_translator(\&translator);
    while (my $input = <DATA>) {
        chomp $input;
        my ($text, $expected) = split /\s+/, $input, 2;
        if ($text =~ $calculator) {
            is $/{Answer}, $expected => "Input $.: $text"; 
        }
        else {
            is_deeply \@!, eval($expected), => "Input $.: $text";
        }
    }
}

{
    use Regexp::Grammars;

    if ('foo' =~ m{ <Answer> <rule: Answer> <...> }xms) {
        fail    'Restore default translator';
    }
    else {
        is_deeply \@!, ["Can't match subrule <Answer> (not implemented)"]
            => 'Restore default translator';
    }
}

__DATA__
2           2

2*3+4       10

2zoo        [
             "Extra junk after expression at index 1: 'zoo'",
             "Wanted end of input, but was given 'zoo'. What's up with that?",
             "Main pattern failed to match 'zoo'",
             "You forgot to define Trailing_stuff. :-(",
            ]

zoo         [
             "<Literal> failed to match 'zoo'",
             "You forgot to define Trailing_stuff. :-(",
            ]
