

use strict;
use warnings;

use Test;
use Term::ANSIColorx::ColorNicknames qw(:all);

plan tests => 3;

my $string = color("red") . "red " . color("sky") . "sky" . color("reset");

ok( $string, qr/\e\[31mred/ );
ok( $string, qr/\e\[1;34msky/ );
ok( $string, qr/\e\[0?m$/ );
