use v5.10;
use warnings;

my $calculator = do{
    use Regexp::Grammars;
    qr{
        \A
        <Answer>

        <rule: Answer>
            <[Operand=Mult]>+ % <[Op=(\+|\-)]>

        <rule: Mult>
            <[Operand=Pow]>+ % <[Op=(\*|/|%)]>

        <rule: Pow>
            <[Operand=Term]>+ % <Op=(\^)>

        <rule: Term>
                <MATCH=Literal>
          |
            \(  <MATCH=Answer>  \)

        <token: Literal>
            <MATCH=( [+-]? \d++ (?: \. \d++ )?+ )>
    }xms
};

package Calculator_Actions;

use List::Util qw< reduce >;

sub Answer {
    my ($self, $MATCH_ref) = @_;

    my $value = shift @{$MATCH_ref->{Operand}};
    for my $term (@{$MATCH_ref->{Operand}}) {
        my $op = shift @{$MATCH_ref->{Op}//=[]};
        if ($op eq '+') { $value += $term; }
        else            { $value -= $term; }
    }

    return $value;
}

sub Mult {
    my ($self, $MATCH_ref) = @_;

    reduce { eval($a . shift(@{$MATCH_ref->{Op}}) . $b) }
           @{$MATCH_ref->{Operand}};
}

sub Pow {
    my ($self, $MATCH_ref) = @_;

    reduce { $b ** $a } reverse @{$MATCH_ref->{Operand}};
}


# and later...

while (my $input = <>) {
    if ($input =~ $calculator->with_actions('Calculator_Actions') ) {
        say '--> ', $/{Answer};
    }
}

