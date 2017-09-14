use Test::More skip_all => "Work in progress";
use utf8;

use Encode;
BEGIN {
    use_ok 'TeX::Encode';
}

my %samples = (
    'nop'       => 'nop',
    '!'       => '!',
);

while (my ($unicode, $expected) = each %samples) {
    my $got = encode 'LaTeX', $unicode;
    is $got, $expected, "TeXing $unicode";
}
done_testing;


