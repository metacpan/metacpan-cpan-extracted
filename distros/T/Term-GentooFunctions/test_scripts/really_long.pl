
die "you're not running this right, use make test" unless -d "blib/lib";
BEGIN { unshift @INC, "blib/lib" }

use strict;
use warnings;
use Term::GentooFunctions qw(:all);

my $long = "xXx " x 50;

for(1..3) {
    edo $long => sub {};
}

print "\n\n";

start_spinner $long;
for( 1 .. 3 ) {
    step_spinner $long;
    sleep 1;
}
end_spinner 1;
