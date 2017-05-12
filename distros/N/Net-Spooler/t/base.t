# -*- perl -*-

print "1..1\n";

$| = 1;
$^W = 1;

my $test = 0;
foreach my $package (qw(Net::Spooler)) {
    ++$test;
    eval "use $package";
    if ($@) {
	print "not ok $test\n";
	print STDERR "\n$@\n";
    } else {
	print "ok $test\n";
    }
}
