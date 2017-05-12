# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 9 };
use Speech::Recognizer::ViaVoice;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# autoflush
$| = 1;

if (ok(connectEngine == 0)) {
	my $ar = ['hello', 'world'];
	if (ok(defineVocab('test', $ar) == 0)) {
		if (ok(startListening == 0)) {
			print "say \"hello\" or \"world\" now... ";
			if (recognize == 0) {
				print "\n";
				ok(1);
				my ($s, $score) = (getWord, getScore);
				printf "%s : %d\n", $s, $score;
				ok( ($s eq 'hello') or ($s eq 'world') );
				ok($score > 5);
			}
			ok(stopListening == 0);
		}
	}
	ok(disconnectEngine == 0);
	print "tests are done!\n";
}
