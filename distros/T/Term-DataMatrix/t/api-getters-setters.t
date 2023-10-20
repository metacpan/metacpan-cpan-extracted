#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require_ok('Term::DataMatrix');

my @attrs = qw/
    black
    black_text
    text_dmcode
    white
    white_text
/;
my %testvals = (
    white => 'on_green',
    black => 'on_red',
);

my $dmcode;

foreach my $attr (@attrs) {
    my $val = $testvals{$attr} // 'testval';

    # Test 0: Attribute passed into new() is reflected via class property.
    $dmcode = Term::DataMatrix->new($attr => $val);
    is($dmcode->{$attr}, $val,
        "attribute set via ->new() should be reflected via ->{$attr}"
    );

}
