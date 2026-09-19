use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
	use_ok 'Music::NWC2MusicXML';
	use_ok 'Music::NWC2MusicXML::NWC';
	use_ok 'Music::NWC2MusicXML::Parser';
	use_ok 'Music::NWC2MusicXML::Score';
	use_ok 'Music::NWC2MusicXML::Staff';
	use_ok 'Music::NWC2MusicXML::Event';
	use_ok 'Music::NWC2MusicXML::MusicXML';
	use_ok 'Music::NWC2MusicXML::Diagnostics';
}

diag "Music::NWC2MusicXML $Music::NWC2MusicXML::VERSION loaded";
