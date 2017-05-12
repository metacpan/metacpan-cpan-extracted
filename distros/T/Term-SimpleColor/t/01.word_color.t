use strict;
use warnings;
use utf8;
use Test::More;

use Term::SimpleColor;

my %COLOR = (
    black   => "\x1b[30m",
    red     => "\x1b[31m",
    green   => "\x1b[32m",
    yellow  => "\x1b[33m",
    blue    => "\x1b[34m",
    magenta => "\x1b[35m",
    cyan    => "\x1b[36m",
    white   => "\x1b[37m",
    default => "\x1b[39m",
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
        my $ideal  = $COLOR{$color} . $test_str . $COLOR{'default'};

        is( $result, $ideal );
        done_testing();
    };

}

done_testing();
1;
