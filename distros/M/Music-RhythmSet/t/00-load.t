#!perl
use 5.24.0;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok('Music::RhythmSet::Voice') || print "Bail out!\n";
    use_ok('Music::RhythmSet::Util')  || print "Bail out!\n";
    use_ok('Music::RhythmSet')        || print "Bail out!\n";
}

diag("Testing Music::RhythmSet $Music::RhythmSet::VERSION, Perl $], $^X");
