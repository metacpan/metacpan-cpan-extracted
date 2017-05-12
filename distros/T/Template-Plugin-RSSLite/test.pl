# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test;
BEGIN { plan tests => 3 };
print "Trying to load required modules...       ";
use Template;
use lib qw/ blib /;
my $tt = new Template();
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

print "Trying to process template with tt...    ";
my $out = "";
$tt->process("test/Templates/one",undef,\$out) || die $tt->error()."\n";
ok(2);
print "Comparing output with what's expected... ";
my $VAR1;
$out = eval($out);
die "Did not produce the expected output!" unless ($out->{'rdf:RDF'}->{'channel'}->{'title'} eq 'Slashdot: News for nerds, stuff that matters');
ok(3);
print "Seems like you are ready to rock and roll! :)\n";

