
use Test::More;

plan tests => 30;

open(STDOUT, ">&STDERR");


system("mkdir t/testdir 2>/dev/null");

for (my $i = 0; $i < 1000; $i++) {
	system("libnf/examples/lnf_ex01_writer -f t/testdir/$i -r 10 -n 300 2>&1 >/dev/null");
}

# get result wiyh single thread 
system("./libnf/bin/nfdumpp -R t/testdir --num-threads=1 -A srcip -O bytes > t/threads-reference.txt 2>t/err");


for (my $i = 1; $i < 24; $i++) {

#	system("./libnf/bin/nfdumpp -R t/testdir --num-threads $i -A srcip  -O dstip > t/threads-res-$i.txt 2>t/err");
	system("./libnf/bin/nfdumpp -R t/testdir --num-threads $i -A srcip -O bytes > t/threads-res-$i.txt 2>t/err");

	system("diff t/threads-reference.txt t/threads-res-$i.txt");

	if ($? != 0) {
		diag("\nInvalid result for $i threads\n");
	}

    ok( $? == 0 );
}

# test with no aggregation 
system("./libnf/bin/nfdumpp -R t/testdir --num-threads=1 2>t/err | sort > t/threads-reference-na.txt");
for (my $i = 1; $i < 8; $i++) {

	system("./libnf/bin/nfdumpp -R t/testdir --num-thread $i 2>t/err | sort > t/threads-res-$i-na.txt");

	system("diff t/threads-reference-na.txt t/threads-res-$i-na.txt");

	if ($? != 0) {
		diag("\nInvalid result for $i threads with no aggregation\n");
	}

    ok( $? == 0 );
}

