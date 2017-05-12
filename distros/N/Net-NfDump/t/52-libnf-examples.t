
use Test::More;

plan tests => 1009;

#open(STDOUT, ">&STDERR");

# prepare testfile 
system("libnf/examples/lnf_ex01_writer -f t/testfile -r 10 -n 30000");
ok( $? == 0 );

# test reader 
open F1, "libnf/examples/lnf_ex02_reader -f t/testfile 2>&1 |";
my $count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 30003);

# test aggreg 
open F1, "libnf/examples/lnf_ex03_aggreg -P -f t/testfile 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 12);

# threads
# prepare testdir 
system("mkdir t/testdir 2>/dev/null");

for (my $i = 0; $i < 1000; $i++) {
	system("libnf/examples/lnf_ex01_writer -f t/testdir/$i -r 10 -n 300");
	ok( $? == 0 );
}

open F1, "libnf/examples/lnf_ex04_threads -P t/testdir/* 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 12);

# threads in list mode 
open F1, "libnf/examples/lnf_ex04_threads -l -P t/testdir/* 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 300002);


# memtrans
open F1, "libnf/examples/lnf_ex05_memtrans -P -f t/testfile 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 12);

# readreset
open F1, "libnf/examples/lnf_ex06_readreset -P -f t/testfile 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 24);


# statistics
open F1, "libnf/examples/lnf_ex08_statistics -f t/testfile 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 13);


# statistics
open F1, "libnf/examples/lnf_ex09_memlookup -P -f t/testfile 2>&1 |";
$count = 0;
while (<F1>) { $count++; };
close F1;

ok($count == 6);



