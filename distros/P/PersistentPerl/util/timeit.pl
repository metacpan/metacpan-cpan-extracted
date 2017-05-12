
use strict;

my($cmd, $numruns) = @ARGV;
close(STDOUT);

while ($numruns--) {
    system($cmd, './test.pl', 'p=20');
}
