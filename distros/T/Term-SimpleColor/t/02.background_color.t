use strict;
use warnings;
use utf8;
use Test::More;

use Term::SimpleColor;

my %COLOR = (
    bg_black  => "\x1b[40m",
    bg_red    => "\x1b[41m",
    bg_green  => "\x1b[42m",
    bg_yellow => "\x1b[43m",
    bg_blue   => "\x1b[44m",
    bg_magenta => "\x1b[45m",
    bg_cyan   => "\x1b[46m",
    bg_gray   => "\x1b[47m",
    bg_default   => "\x1b[49m",
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
        my $ideal  = $COLOR{$color} . $test_str . $COLOR{'bg_default'};

        is( $result, $ideal );
        done_testing();
    };

}

done_testing();
1;
