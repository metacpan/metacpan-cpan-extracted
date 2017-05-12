use Test::More qw/no_plan/;

use strict;
use warnings;

`$^X -Ilib ./t/bin/log.pl`;
open my $in, "<", "./t/tmp/error_log.txt" or die $!;

my $line = '';
while (<$in>) {
  $line .= $_;
}
close $in;
open my $out, ">", "./t/tmp/error_log.txt" or die $!;
close $out;

ok($line =~m{\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+
Died 123456789 at ./t/bin/log.pl line 5.
\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+
Died 223456789 at ./t/bin/log.pl line 6.
\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+
Died 323456789 at ./t/bin/log.pl line 7.
\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+
Died 423456789 at ./t/bin/log.pl line 8.
}, $line);
