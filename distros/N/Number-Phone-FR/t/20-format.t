use strict;
use warnings;

use Number::Phone::FR;

use lib 't/lib';
use Numeros;

use Test::More tests => 2*@Numeros::formatted
                      + 1;
use Test::NoWarnings;

foreach my $fmt (@Numeros::formatted) {
    my $s = $fmt;
    $s =~ s/[^+0-9]//g;
    my $num = Number::Phone::FR->new($s);
    isa_ok($num, 'Number::Phone::FR', "'$s'");
    SKIP: {
        skip "object creation failed", 1 unless defined $num;

        is($num->format, $fmt, "format for $s");
    }
}
