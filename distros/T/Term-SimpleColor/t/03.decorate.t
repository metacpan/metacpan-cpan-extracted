use strict;
use warnings;
use utf8;
use Test::More;

use Term::SimpleColor;

my %COLOR = (
    underscore => "\x1b[4m",
    bold => "\x1b[1m",
    invert => "\x1b[7m",
    dc_default => "\x1b[0m",
);

for my $color (keys(%COLOR)) {

    subtest $color => sub {

	my $method = 'Term::SimpleColor::' . $color;

        my $result = eval("\&$method()");
        my $ideal  = $COLOR{$color};

        is( $result, $ideal );
        done_testing();
    };


    subtest $color . " with a string paramater" => sub {

	my $method = 'Term::SimpleColor::' . $color;

	my $test_str = 'string';
        my $result = eval("\&$method( \$test_str )");
        my $ideal  = $COLOR{$color} . $test_str . $COLOR{'dc_default'};

        is( $result, $ideal );
        done_testing();
    };

}

done_testing();
1;
