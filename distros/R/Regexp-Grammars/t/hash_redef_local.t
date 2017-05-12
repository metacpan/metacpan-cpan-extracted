use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

my %hash = (
    dore => 'a portal',
    me   => 'a name I call myself',
    fa   => 'a long long way to run',
);

my $listified = do {
    use Regexp::Grammars;
    qr{ <[WORD=%hash{ .{2} }]>+ }xms;
};

my $first_only = do {
    use Regexp::Grammars;
    qr{ <WORD=%hash {.{2}} > }xms;
};

my $first_only_override = do {
    use Regexp::Grammars;
    qr{ <WORD=%hash {.{2}} >  <token: hk> \w+ }xms;
};

my $first_two_override = do {
    use Regexp::Grammars;
    qr{ <WORD1=%hash {.{2}} > <WORD2=%hash{..}>  <token: hk> \w+ }xms;
};

my $no_cap = do {
    use Regexp::Grammars;
    qr{ <%hash{..}>+ }xms;
};

while (my $line = <DATA>) {
    my ($input, $expected) = split /\s+/, $line;
    my $expected_data = eval $expected;

    if ($input =~ $listified) {
        is_deeply $/{WORD}, $expected_data, "list:   $input";
    }
    else { is 'FAIL', $expected, "list:   $input"; }

    if ($input =~ $first_only) {
        is $/{WORD}, $expected_data->[0], "scalar: $input";
    }
    else { is 'FAIL', $expected, "scalar: $input"; }

    if ($input =~ $first_only_override) {
        is $/{WORD}, $expected_data->[0], "scalar (override): $input";
    }
    else { is 'FAIL', $expected, "scalar (override): $input"; }

    if (@{$expected_data} > 1) {
        if ($input =~ $first_two_override) {
            is $/{WORD1}, $expected_data->[0], "scalars[0] (override): $input";
            is $/{WORD2}, $expected_data->[1], "scalars[1] (override): $input";
        }
        else { is 'FAIL', $expected, "scalars (override): $input"; }
    }

    if ($input =~ $no_cap) { isnt 'FAIL', $expected, "no-cap:  $input"; }
    else                   {   is 'FAIL', $expected, "no-cap:  $input"; }

}

__DATA__
dorefameredo    ['fa','me']
dorefamell      ['fa','me']
zzzzz           FAIL
zzzdoremezzz    ['me']
