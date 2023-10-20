#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use Term::ANSIColor qw/ colored /;

require_ok('Term::DataMatrix');

my %defaults = (
    black_text => sub {
        my ($val, $dmcode) = @_;
        return $val eq colored('  ', 'on_black');
    },
    white_text => sub {
        my ($val, $dmcode) = @_;
        return $val eq colored('  ', 'on_white');
    },
    text_dmcode => sub {
        my $val = shift;
        return ref $val && $val->isa('Barcode::DataMatrix');
    },
);

while (my ($attr, $expected) = each %defaults) {
    my $test_name = "default value for ->{$attr} should match expected";
    my $dmcode = Term::DataMatrix->new;
    my $val = $dmcode->{$attr};
    if (ref $expected eq 'CODE') {
        ok(scalar $expected->($val, $dmcode),
            $test_name
        );
    } else {
        is($val, $expected,
            $test_name
        );
    }
}
