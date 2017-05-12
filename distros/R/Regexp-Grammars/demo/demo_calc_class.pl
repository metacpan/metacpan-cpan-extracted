use v5.10;
use warnings;

my $calculator = do{
    use Regexp::Grammars;
    qr{
        <Answer>

        <objrule: Answer>
            <X=Mult> <Op=([+-])> <Y=Answer>
          | <MATCH=Mult>

        <objrule: Mult>
            <X=Pow> <Op=([*/%])> <Y=Mult>
          | <MATCH=Pow>

        <objrule: Pow>
            <X=Term> <Op=(\^)> <Y=Pow>
          | <MATCH=Term>

        <objrule: Term>
               <MATCH=Literal>
          | <Sign=([+-]?)> \( <Answer> \)
          | \( <MATCH=Answer> \)

        <objtoken: Literal>
            <value=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

while (my $input = <>) {

    my $debug = $input =~ s{^show \s+}{}xms;

    if ($input =~ $calculator) {
        if ($debug) {
            use Data::Dumper 'Dumper';
            warn Dumper \%/;
        }
        else {
            say '--> ', $/{Answer}->eval();
        }
    }
}

sub Answer::eval {
    my ($self) = @_;

    my $x = $self->{X}->eval();
    my $y = $self->{Y}->eval();
    return $self->{Op} eq '+'  ?  $x + $y
         :                        $x - $y;
}

sub Mult::eval {
    my ($self) = @_;

    my $x = $self->{X}->eval();
    my $y = $self->{Y}->eval();
    return $self->{Op} eq '*'  ?  $x * $y
         : $self->{Op} eq '/'  ?  $x / $y
         :                        $x % $y;
}

sub Pow::eval {
    my ($self) = @_;

    return $self->{X}->eval() **  $self->{Y}->eval();
}

sub Term::eval {
    my ($self) = @_;

    return $self->{Sign} eq '-' ? -$self->{Answer}->eval()
                                :  $self->{Answer}->eval();
}

sub Literal::eval {
    my ($self) = @_;

    return $self->{value};
}
