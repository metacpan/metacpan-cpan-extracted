use Test::More qw/no_plan/;

use strict;
use warnings;

`$^X -Ilib ./t/bin/file-die.pl`;
open my $in, "<", "./t/tmp/error_log.txt" or die $!;
my $line = <$in>;
close $in;
is($line, undef);

