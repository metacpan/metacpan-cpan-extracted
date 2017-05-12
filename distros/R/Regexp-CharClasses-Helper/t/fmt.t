use Test::More;
use Test::FailWarnings;

BEGIN {
    use_ok 'Regexp::CharClasses::Helper';
}

#is(Regexp::CharClasses::Helper::fmt("+\t\t"), "002b\t0009", 'temp');

my %testcases = (
    'A'          => ord 'A',
    '+'          => ord '+',
    '0'          => ord '0',
    "\0"         => 0,
    "\1"         => 1,
    'LATIN SMALL LETTER B'
                 => ord 'b',
    "\x42"       => 0x42,
    "\N{U+1337}" => 0x1337,
    ' '          => ord ' ',
    "\t"         => ord "\t",
);
$testcases{$_} = sprintf '%04x', $testcases{$_} for (keys %testcases);

while(my ($k, $v) = each %testcases) {
    is(Regexp::CharClasses::Helper::fmt($k), "$v\n", 'single');
}
while(my ($k, $v) = each %testcases) {
    is(Regexp::CharClasses::Helper::fmt($_.$k), "$_$v\n", 'prefixed') for qw/- + ! &/;
}
my %testcases2 = %testcases;
while(my ($k1, $v1) = each %testcases) {
    while(my ($k2, $v2) = each %testcases2) {
        for my $prefix (qw(- + ! &), '') {
            is(
                Regexp::CharClasses::Helper::fmt("$prefix$k1\t$k2"),
                "$prefix$v1\t$v2\n",
                'range'
            );
        }
    }
}

#TODO: iterate over subsets?
is(
    Regexp::CharClasses::Helper::fmt(keys %testcases),
    join("\n", values %testcases)."\n",
    'multi-line'
);
    



done_testing
