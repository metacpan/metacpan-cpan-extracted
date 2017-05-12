#!perl -w

use strict;
eval { require warnings; }; #it's ok if we can't load warnings

my @tests = (
	{ msg => "nonexistent process" },
	{ msg => "process owned by another user" },
	{ msg => "process owned by you", xtra => 'enter for $$' },
);

foreach my $test (@tests) {
	my $m = $test->{msg};
	print "Input the pid of a ".$test->{msg};
	print ' ('.$test->{xtra}.')' if($test->{xtra});
	print ': ';
	my $pid = <>;
	chomp($pid);
	$pid = $$ if($pid eq '' && $test->{xtra});
	my $ret = kill(0, $pid);
	$test->{err} = $!; 
	$test->{errno} = 0+$!; 
	$test->{ret} = $ret; 
}

print "\n\n=== results ===\nOS: $^O\n"; 
foreach my $test (@tests) {
	my ($m, $ret, $err, $errno) =
     ($test->{msg}, $test->{ret}, $test->{err},  $test->{errno});
	print "$m test got ret: $ret, \$!: $errno ($err)\n";
}

