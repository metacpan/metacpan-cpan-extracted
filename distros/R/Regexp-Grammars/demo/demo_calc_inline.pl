use v5.10;
use warnings;

my $calculator = do{
    use Regexp::Grammars;
    qr{
        <Answer>

        <rule: Answer>
            <X=Mult> \+ <Y=Answer>
                (?{ $MATCH = $MATCH{X} + $MATCH{Y}; })
          | <X=Mult> - <Y=Answer>
                (?{ $MATCH = $MATCH{X} - $MATCH{Y}; })
          | <MATCH=Mult>

        <rule: Mult>
            <X=Pow> \* <Y=Mult>
                (?{ $MATCH = $MATCH{X} * $MATCH{Y}; })
          | <X=Pow>  / <Y=Mult>
                (?{ $MATCH = $MATCH{X} / $MATCH{Y}; })
          | <X=Pow>  % <Y=Mult>
                (?{ $MATCH = $MATCH{X} % $MATCH{Y}; })
          | <MATCH=Pow>

        <rule: Pow>
            <[Term]>+ % \^
                (?{
                    $MATCH = 1;
                    $MATCH = $_ ** $MATCH for reverse @{$MATCH{Term}};
                })
            |
                <MATCH=Term>

        <rule: Term>
            <MATCH=Literal>
          | - \( <Answer> \) <MATCH= (?{ -1 * $MATCH{Answer} })>
          | [+]? \( <MATCH=Answer> \)

        <token: Literal>
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

while (my $input = <>) {
    if ($input =~ $calculator) {
        say '--> ', $/{Answer};
    }
}
