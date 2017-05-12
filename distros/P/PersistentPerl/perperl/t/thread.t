
my $x = `$ENV{PERPERL} t/scripts/thread 1 2>/dev/null`;
if ($x =~ /ok/) {
    my $x = `$ENV{PERPERL} t/scripts/thread`;
    print "1..1\n";
    my $ok = ($x eq "x\nx\n");
    print $ok ? "ok\n" : "not ok\n";
} else {
    print "1..0  # Skipped: Not running a threaded perl\n";
}
