use Test::More qw/no_plan/;

use strict;
use warnings;

`$^X -Ilib ./t/bin/file.pl`;
open my $in, "<", "./t/tmp/error_log.txt" or die $!;
my $line = <$in>;
chomp($line);
close $in;
open my $out, ">", "./t/tmp/error_log.txt" or die $!;
close $out;

is($line, q{Died 123456789 at ./t/bin/file.pl line 5.});
