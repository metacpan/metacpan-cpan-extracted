use v5.10;
use warnings;

my $calculator = do{
    use Regexp::Grammars;
    qr{ 
        <Answer>

        <rule: Answer>
            <X=Mult> <Op=([+-])> <Y=Answer>
          | <MATCH=Mult>

        <rule: Mult>
            <X=Pow> <Op=([*/%])> <Y=Mult>
          | <MATCH=Pow>

        <rule: Pow>
            <X=Term> <Op=(\^)> <Y=Pow>
          | <MATCH=Term>

        <rule: Term>
            <MATCH=Literal>
          | <Sign=([-+])> \( <Answer> \)
          | \( <MATCH=Answer> \)

        <token: Literal>
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

while (my $input = <>) {
    if ($input =~ $calculator) {
        use Data::Dumper 'Dumper';
        warn Dumper \%/;
    }
}
