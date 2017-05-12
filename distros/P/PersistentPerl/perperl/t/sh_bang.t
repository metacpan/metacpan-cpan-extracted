
# Check if the sh_bang line (the #! line embedded in the perl script)
# is actually being read correctly for perperl options.

# On some OSes (Linux) you'll get the #! arguments in argv when the program
# is exec'ed.  On others (Solaris) you have to read the file yourself
# to get all the options.


my $tmp = "/tmp/sh_bang.$$";

print "1..2\n";

open(F, ">$tmp") || die;
print F "#!$ENV{PERPERL} -w -- -t5 -r2\nprint ++\$x; \$x = \$x;\n";
close(F);
sleep 1;
chmod 0755, $tmp;

my @nums = map {`$tmp`} (0..3);
sleep 1;
unlink($tmp);

my $failed = 0;
for (my $i = 0; $i < 4; ++$i) {
    if ($nums[$i] != ($i % 2) + 1) {
	$failed++;
	last;
    }
}

print $failed ? "not ok\n" : "ok\n";

my $scr = 't/scripts/sh_bang.2';
utime time, time, $scr;
sleep 1;


sub onerun {
    my $pid = open(F, '-|');
    if (!$pid) {
	$^W = 0;
	eval {exec($ENV{PERPERL}, $scr)};
	exit(1);
    }
    $SIG{ALRM} = sub {kill 9, $pid};
    alarm(3);
    return scalar <F> =~ /ok/;
}

&onerun;
print &onerun ? "ok\n" : "not ok\n";
alarm(0);
