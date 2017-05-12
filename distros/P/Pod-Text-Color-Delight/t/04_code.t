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
my $pod_file = catfile($FindBin::Bin, 'resources', 'code.pod');
my $got      = capture_stdout{ $delight->parse_from_file($pod_file) };

is $got, <<"...", 'Code ok';
\e[1m\e[96mheadline\e[0m\e[0m
        \e[38;5;242m# Do nothing\e[0m
        \e[91msub\e[0m \e[38;5;194mfunc\e[0m \e[37m{\e[0m
            \e[91mmy\e[0m \e[37m(\e[0m\e[38;5;208m\$self\e[0m\e[37m,\e[0m \e[38;5;208m\$args\e[0m\e[37m)\e[0m \e[37m=\e[0m \e[38;5;208m\@_\e[0m\e[37m;\e[0m
            \e[91mreturn\e[0m\e[37m;\e[0m
        \e[37m}\e[0m

        \e[37mMyApp\e[0m\e[37m->\e[0m\e[38;5;194mfunc\e[0m\e[37m(\e[0m\e[37m)\e[0m\e[37m;\e[0m

        __END__

...

done_testing;
