
# The backend tries to keep some file descriptors open between perl runs.
# But if the perl program messes up those fds it should be able to recover.
# Still can't recover current directory.

my $scr = 't/scripts/mungefds';

print "1..2\n";

system("$ENV{PERPERL} $scr >/dev/null");
utime time, time, $scr;
sleep 1;

sub doit { my $open_dev_null = shift;
    open(F, "$ENV{PERPERL} $scr $open_dev_null |");
    my @lines = <F>;
    close(F);
    return @lines;
}

sub doit2 { my $open_dev_null = shift;
    my @first = &doit($open_dev_null);
    sleep 1;
    my @second = &doit($open_dev_null);

    #print STDERR "first=",join(":", @first), "\n";
    #print STDERR "second=",join(":", @second), "\n";

    if (@first != 1 || $first[0] ne $second[0]) {
	print "not ok\n";
    } else {
	print "ok\n";
    }
}

&doit2(0);
sleep 1;
&doit2(1);
