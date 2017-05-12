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
my $pod_file = catfile($FindBin::Bin, 'resources', 'item_after_code.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", "Show certainly item after C<...> element";
\e[1m\e[96mfoo\e[0m\e[0m
    \"\e[37muser\e[0m\"

    type is secret

...

done_testing;
