# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

my @gencat = qw(
	gencat
	/bin/gencat /usr/bin/gencat /usr/sbin/gencat /sbin/gencat
	/etc/gencat /usr/etc/gencat /usr/local/bin/gencat
);

use Locale::Msgcat;
$loaded = 1;
print "ok 1\n";

## Generate the catalog
if (MakeCat() != 0) {
   print "not ok 2\n";
   exit 0;
}
print "ok 2\n";

unless ($a = new Locale::Msgcat) {
   print "not ok 2\n";
   exit 0;
}
print "ok 2\n";

unless ($a->catopen("./sample.cat", 1)) {
   print "not ok 3\n";
   exit 0;
}
print "ok 3\n";

print "not " if ($a->catgets(1, 1, "test") ne "Hi there ?");
print "ok 4\n";
print "not " if ($a->catgets(2, 1, "test") ne "It's raining.");
print "ok 5\n";
print "not " if ($a->catgets(2, 2, "test") ne "test");
print "ok 6\n";
print "not " unless ($a->catclose());
print "ok 7\n";

unlink("sample.cat");
exit 0;

## Makes the message catalog
sub MakeCat {
   my $i;

   while ($i = shift(@gencat)) {
      return 0 if (system("$i sample.cat sample.msg") == 0);
   }
   return 1;
}
