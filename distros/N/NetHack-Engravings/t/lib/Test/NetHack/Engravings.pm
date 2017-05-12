package Test::NetHack::Engravings;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = ('degrade_ok', 'degrade_nok', 'degrade_progression');

use NetHack::Engravings 'is_degradation';

sub degrade_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $exp = shift;
    my $got = shift;

    Test::More::ok(is_degradation($exp, $got), "$exp degrades to $got");
}

sub degrade_nok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $exp = shift;
    my $got = shift;

    Test::More::ok(!is_degradation($exp, $got), "$exp does not degrade to $got");
}

sub degrade_progression {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for (my $i = 0; $i < @_; ++$i) {
        for (my $j = $i; $j < @_; ++$j) {
            degrade_ok($_[$i] => $_[$j]);
            degrade_nok($_[$j] => $_[$i]) unless $_[$i] eq $_[$j];
        }
    }
}

1;
