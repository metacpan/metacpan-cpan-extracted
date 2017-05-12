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
my $pod_file = catfile($FindBin::Bin, 'resources', 'heads.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", 'headlines Highlight ok';
\e[1m\e[96mfoo\e[0m\e[0m
  \e[1m\e[0;1mbar\e[0m\e[0m
   \e[0mbaz\e[0m
   \e[0mqux\e[0m
...

done_testing;
