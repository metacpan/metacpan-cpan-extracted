#!perl
use strict;

package foo;
my $file = shift;
exit unless $file;

eval { print FOO "can't happen\n" };
open FOO, ">>$file" or die "can't open '$file' $!";
print FOO join(' ', @ARGV), "\n";

