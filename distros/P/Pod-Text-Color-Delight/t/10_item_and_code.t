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
my $pod_file = catfile($FindBin::Bin, 'resources', 'item_and_code.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", "Do not treat as CODE when it is in item section.";
    \"\$foo = \"bar\"\"
    foo
    \"\$bar = \"baz\"\"

    \"\e[38;5;208m\$bar\e[0m \e[37m=\e[0m \e[38;5;222m\"\e[0m\e[38;5;222mbaz\e[0m\e[38;5;222m\"\e[0m\"

...

done_testing;
