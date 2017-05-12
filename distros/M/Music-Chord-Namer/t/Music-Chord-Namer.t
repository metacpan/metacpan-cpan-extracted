# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Music-Chord-Namer.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Music::Chord::Namer') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my %testchords = (
	'C E G C' => 'C',
	'C Eb Gb C' => 'Co',
	'C Eb G C' => 'Cm',
	'C E G B' => 'Cmaj7',
	'C E G Bb' => 'C7',
	'C E G Bb D' => 'C9',
	'C E G Bb D F' => 'C11',
	'C E G Bb D F A' => 'C13'
);

foreach my $k (keys %testchords){
	ok($testchords{$k} eq Music::Chord::Namer::chordname($k),$k.' -> '.$testchords{$k});
}
