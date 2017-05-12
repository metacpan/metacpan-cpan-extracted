
use strict;
use warnings;

use Test;
use Term::ANSIColorx::ColorNicknames qw(fix_color);

my %fix_these = (
    "bold-blue on white" => "bold blue on_white",
    "bold sky-on-white"  => "bold blue on_white",
    "\ayellow"           => "yellow",
    pitch                => "bold black",
);

plan tests => 0 + (keys %fix_these);

ok( fix_color $_, $fix_these{$_} )
    for keys %fix_these;
