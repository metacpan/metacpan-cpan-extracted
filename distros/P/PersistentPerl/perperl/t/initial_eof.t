
# Solaris's select() won't wake up when stdin is initially EOF.
# To reproduce this bug, compile on Solaris with USE_SELECT defined.

# SGI's select won't wake up when script output is redirected to /dev/null.

print "1..2\n";

sub wakeup { print "not ok\n"; exit }

$SIG{ALRM} = \&wakeup;

alarm(3);
my $line = `$ENV{PERPERL} t/scripts/initial_eof </dev/null`;
print $line =~ /ok/ ? "ok\n" : "not ok\n";

alarm(3);
$line = `$ENV{PERPERL} t/scripts/initial_eof <t/scripts/initial_eof >/dev/null`;
print $? ? "not ok\n" : "ok\n";

alarm(0);
