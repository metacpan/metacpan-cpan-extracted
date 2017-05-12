# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use CTPort;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$ctport = new Telephony::CTPort(1200); # first port of CT card

# start test 2 - play a beep and few pre-recorded prompts

$ctport->off_hook;
$ctport->play("beep");                 
$ctport->play("1 2 3");                 # play back

print "ok 2\n";

# start test 3 - record and play back a 2 second audio file

$ctport->record("prompt.wav", 2, "");
$ctport->play("prompt.wav");                 

print "ok 3\n";

my $digits = $ctport->collect(2, 2);
$ctport->play($ctport->number($digits));
$ctport->dial($digits);

print "ok 4\n";

$ctport->on_hook;




