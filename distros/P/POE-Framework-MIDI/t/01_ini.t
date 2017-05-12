# t/01_ini.t; just to load POE::Framework::MIDI by using it

$|++; 
print "1..1
";
my($test) = 1;

# 1 load

# control objects
use lib '../lib';
use POE;
use POE::Framework::MIDI::POEConductor;
use POE::Framework::MIDI::Conductor;

use POE::Framework::MIDI::POEMusician;
use POE::Framework::MIDI::Musician;
# containers
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Phrase;
use POE::Framework::MIDI::Ruleset;
use POE::Framework::MIDI::Rule;
# utility and lookup
use POE::Framework::MIDI::Utility;
use POE::Framework::MIDI::Key;
# events
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;
use POE::Framework::MIDI::Noop; 

# test musician
use POE::Framework::MIDI::Musician::Test;

my($loaded) = 1;
$loaded ? print "ok $test
" : print "not ok $test
";

$poe_kernel->run();

# end of t/01_ini.t

