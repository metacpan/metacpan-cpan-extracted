#test that WM constructor and get_wme are correct

use strict;
use warnings;
use Test::More tests => 3 + 1;    #+ 1 for NoWarnings auto-test
use Test::NoWarnings;

use Soar::WM;
use Data::Section::Simple qw(get_data_section);

my $class   = 'Soar::WM';
my $allData = get_data_section;

my $wmText = $allData->{'small text'};
my $wm = Soar::WM->new(text=>$wmText);
isa_ok( $wm, 'Soar::WM' );

my $s2 = $wm->get_wme('S2');
isa_ok( $s2, 'Soar::WM::Element' );
is($s2->id, 'S2', 'Correct WME returned from get_wme');

__DATA__
@@ small text
(S1 ^foo bar ^foo buzz ^baz boo ^link S2 ^link S3)
(S2 ^faz far 
	^boo baz
	^fuzz buzz)
(S3 ^junk foo)
