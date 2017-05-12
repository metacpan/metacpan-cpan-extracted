#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use Capture::Tiny qw/capture_stdout/;
use File::Spec::Functions qw/catfile/;
use Pod::Text::Color::Delight;

use Test::More;

BEGIN {
    $ENV{POD_TEXT_COLOR_DELIGHT_DEFAULT} = 1;
}

my $delight  = Pod::Text::Color::Delight->new;
my $pod_file = catfile($FindBin::Bin, 'resources', 'nested_formatting.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", "Nested format ok";
\e[1m\e[96mfoo\e[0m\e[0m
    \"\e[38;5;208m\$foo\e[0m \e[33m\e[0;3mbar\e[0m\e[0m\"

    \"\e[38;5;208m\$foo\e[0m \e[38;5;45mbar\e[0m\"

    \"\e[38;5;208m\$foo\e[0m \e[38;5;45mhttp:example.com\e[0m\"

    \"\e[38;5;208m\$foo\e[0m \e[1m\e[0;1mbar\e[0m\e[0m\"

    \"\e[38;5;208m\$foo\e[0m \e[36m\e[92mbar\e[0m\e[0m \e[36m\e[92mbaz\e[0m\e[0m\"

    \e[36m\e[92m\e[1m\e[0;1mfoo\e[0m\e[0m\e[0m\e[0m

    \e[1m\e[0;1m\"\e[38;5;208m\$foo\e[0m\"\e[0m\e[0m

    \e[33m\e[0;3m\e[1m\e[0;1mfoo\e[0m\e[0m\e[0m\e[0m

    \e[1m\e[0;1m\e[33m\e[0;3mfoo\e[0m\e[0m \"\e[38;5;208m\$bar\e[0m\"\e[0m\e[0m

...

done_testing;
