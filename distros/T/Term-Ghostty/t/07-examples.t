use strict;
use warnings;
use Test::More;
use IPC::Open2 qw(open2);

my $pid = open2(my $out, my $in, $^X, '-Mblib', 'examples/ansi2html.pl');
my @markers = map { sprintf 'ROW%04d:', $_ } 1 .. 100;
print $in $_, 'x' x 1000, "\n" for @markers;
close $in or die "converter input: $!";
my $html = do { local $/; <$out> };
close $out;
waitpid($pid, 0);
is($?, 0, 'ansi2html exits successfully');
is_deeply([$html =~ /(ROW\d{4}:)/g], \@markers, 'ansi2html retains every wrapped log line');

done_testing;
