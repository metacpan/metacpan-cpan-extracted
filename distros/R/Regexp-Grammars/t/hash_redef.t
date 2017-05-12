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
    qr{ <[WORD=%hash]>+ <rule: hk> .{2} }xms;
};

my $first_only = do {
    use Regexp::Grammars;
    qr{ <WORD=%hash> <rule: hk> .{2} }xms;
};

my $no_cap = do {
    use Regexp::Grammars;
    qr{ <%hash>+        <rule: hk> .{2} }xms;
};

while (my $line = <DATA>) {
    my ($input, $expected) = split /\s+/, $line;

    if ($input =~ $listified) {
        is_deeply $/{WORD}, eval($expected), "list:   $input";
    }
    else { is 'FAIL', $expected, "list:   $input"; }

    if ($input =~ $first_only) {
        is $/{WORD}, eval($expected)->[0], "scalar: $input";
    }
    else { is 'FAIL', $expected, "scalar: $input"; }

    if ($input =~ $no_cap) { isnt 'FAIL', $expected, "no-cap:  $input"; }
    else                   {   is 'FAIL', $expected, "no-cap:  $input"; }

}

__DATA__
dorefameredo    ['fa','me']
dorefamell      ['fa','me']
zzzzz           FAIL
zzzdoremezzz    ['me']
