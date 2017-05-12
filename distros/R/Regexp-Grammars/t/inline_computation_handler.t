use 5.010;
use warnings;

package Calculator;
use List::Util qw< reduce >;

sub Answer {
    my ($class, $result_hash) = @_;

    my $sum = shift @{$result_hash->{Operand}};

    for my $term (@{$result_hash->{Operand}}) {
        my $op = shift @{$result_hash->{Op}};
        if ($op eq '+') { $sum += $term; }
        else            { $sum -= $term; }
    }

    return $sum;
}

sub Mult {
    my ($class, $result_hash) = @_;

    return reduce { eval($a . shift(@{$result_hash->{Op}}) . $b) }
                  @{$result_hash->{Operand}};
}

sub Pow {
    my ($class, $result_hash) = @_;

    return reduce { $b ** $a } reverse @{$result_hash->{Operand}};
}


use Test::More 'no_plan'; 

my $calculator = do{
    use Regexp::Grammars;
    qr{
        <Answer>

        <rule: Answer>
            <[Operand=Mult]> ** <[Op=(\+|\-)]>

        <rule: Mult>
            <[Operand=Pow]> ** <[Op=(\*|/|%)]>

        <rule: Pow>
            <[Operand=Term]> ** <Op=(\^)> 

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
    ok +($expr =~ $calculator->with_actions('Calculator')) => "Matched expression: $expr";
    cmp_ok $/{Answer}, '==', $result => "Got right answer ($result)";
}

__DATA__
1+1+1     = 3
2^3*4+5   = 37
2+3*4^5   = 3074
2+3*4+5   = 19
2*3+4*5   = 26
2*(3+4)*5 = 70
2+3+4-5   = 4
100/10/2  = 5
100/10*2  = 20
