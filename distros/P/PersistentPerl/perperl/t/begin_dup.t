
# Test for bug where STDIN/STDOUT could not be duped from within
# a BEGIN clause because fd's 0/1 were closed before parsing perl.

print "1..1\n";
if (fork == 0) {
    open(STDERR, ">/dev/null");
    exec("$ENV{PERPERL} t/scripts/begin_dup");
    exit(1);
}
my $w = wait;
# print STDERR "wait=$w status=$?\n";
if ($w != -1 && $? == 0) {
    print "ok\n";
} else {
    print "not ok\n";
}

