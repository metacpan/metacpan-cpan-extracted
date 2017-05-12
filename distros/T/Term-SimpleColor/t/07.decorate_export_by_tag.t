use strict;
use warnings;
use utf8;
use Test::More;

use Term::SimpleColor qw(:decoration);

my %COLOR = (
    underscore => "\x1b[4m",
    bold => "\x1b[1m",
    invert => "\x1b[7m",
    dc_default => "\x1b[0m",
);

for my $color (keys(%COLOR)) {

    subtest $color => sub {

        my $result = eval("\&$color()");
        my $ideal  = $COLOR{$color};

        is( $result, $ideal );
        done_testing();
    };


    subtest $color . " with a string paramater" => sub {

	my $test_str = 'string';
        my $result = eval("\&$color( \$test_str )");
        my $ideal  = $COLOR{$color} . $test_str . $COLOR{'dc_default'};

        is( $result, $ideal );
        done_testing();
    };

}

done_testing();
1;
