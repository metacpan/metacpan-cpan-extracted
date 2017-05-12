# -*- perl -*-

# t/03-methods.t - check that the methods work

use Test::Simple tests => 4;
use Music::Note::Frequency;

my $note = Music::Note::Frequency->new('C4','ISO');

print $note->frequency() . " should equal 261.625565300599 \n...only testing to 6 places...\n";
ok(sprintf("%.6f",$note->frequency()) == 261.625565);

$note->transpose(9);

print "A4 should be exactly 440 - and it equals " . $note->frequency() . "\n";

ok($note->frequency() == 440);

print "Changing base frequency to 430.5 Hz\n";

ok($note->base(430.5) == 430.5);

$note->transpose(-9);

print "Checking new value of C4\n" . $note->frequency() . " should read 255.976831504336\nagain only testing to 6 places\n";

ok(sprintf("%.6f",$note->frequency()) == 255.976832);

