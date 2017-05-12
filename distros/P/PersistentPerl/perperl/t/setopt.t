
print "1..1\n";

my $cmd = "$ENV{PERPERL} t/scripts/setopt";

my $pid1 = `$cmd`;
sleep 2;
my $pid2 = `$cmd`;

if ($pid1 > 0 && $pid2 > 0 && $pid1 != $pid2) {
    print "ok\n";
} else {
    print "not ok\n";
}

