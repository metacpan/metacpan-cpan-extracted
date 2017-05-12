# test loading

BEGIN { $| = 1; print "1..3\n"; }
END { print "not ok 1\n" unless $loaded; }

use Hints::Base;

$loaded = 1;
print "ok 1\n";

# test output from module

my $hints = new Hints::Base;

print "not " if $hints->count();

print "ok 2\n";

$hints = new Hints::Base 'svplus';

print "not " unless $hints->count();

print "ok 3\n";
