
# Test1: test that two scripts with the same group return the same pid
# Test2: same test, but use a long group name the same in the first 12 chars
# Test3: two different group names should return different pids
# Test4: Does exit cause the backend to die?
# Test5: Does shift/pop work on @ARGV under groups?
# Test6: Must find scripts by dev/ino/group-name, not just by dev/ino

print "1..6\n";

sub check_pids { my($same, $pid1, $pid2) = @_;

    my $ok = $pid1 ne '' && $pid2 ne '' && $pid1 > 0 && $pid2 > 0 &&
	($same ? ($pid1 == $pid2) : ($pid1 != $pid2));

    if ($ok) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
}

sub doit { my($grp1, $grp2, $same) = @_;

    utime time, time, 't/scripts/group1';
    utime time, time, 't/scripts/group2';
    sleep 1;
    my $pid1 = `$ENV{PERPERL} -- -g$grp1 t/scripts/group1`;
    sleep 1;
    my $pid2 = `$ENV{PERPERL} -- -g$grp2 t/scripts/group2`;

    &check_pids($same, $pid1, $pid2);
}

&doit('', '', 1);
&doit('012345678912xyzzy', '012345678912snarf', 1);
&doit('a', 'b', 0);

utime time, time, 't/scripts/group3';
sleep 1;
my $pid1 = `$ENV{PERPERL} -- -g t/scripts/group3`;
my $pid2 = `$ENV{PERPERL} -- -g t/scripts/group3`;
my $ok = $pid1 ne '' && $pid2 ne '' && $pid1 > 0 && $pid1 == $pid2;
print $ok ? "ok\n" : "not ok\n";

my($pid, $shift, $pop) =
    split(/\n/, `$ENV{PERPERL} -- -g t/scripts/group3 shift x pop`);
$ok = defined($shift) && $shift eq 'shift' && defined($pop) && $pop eq 'pop';
print $ok ? "ok\n" : "not ok\n";

utime time, time, 't/scripts/group1';
$ENV{PERPERL_GROUP} = 'a';
$pid1 = `$ENV{PERPERL} -- t/scripts/group1`;
$ENV{PERPERL_GROUP} = 'b';
$pid2 = `$ENV{PERPERL} -- t/scripts/group1`;
delete $ENV{PERPERL_GROUP};
&check_pids(0, $pid1, $pid2);
