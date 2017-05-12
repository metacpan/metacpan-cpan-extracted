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
my $pod_file = catfile($FindBin::Bin, 'resources', 'link_url.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", "Correspond link notation of URL";
\e[1m\e[96murl\e[0m\e[0m
    \e[38;5;45mhttp://example.com\e[0m

...

done_testing;
