#test that slurping is done correctly

use strict;
use warnings;
use Test::More tests => 7 + 1;    #+ 1 for NoWarnings auto-test
use Test::NoWarnings;
use Test::Deep;
use autodie;

use Soar::WM::Slurp qw(read_wm read_wm_file);
use FindBin('$Bin');
use File::Spec;
use Data::Section::Simple qw(get_data_section);

my $allData  = get_data_section;
my $expected = eval( $allData->{'small_eval'} );

# Dump($expected);

#example WME dump is held in the t/data folder
my $WMEfile = File::Spec->catfile( $Bin, 'data', 'wmedumpSmall.txt' );
my ( $wm, $root ) = read_wm_file($WMEfile);
cmp_deeply( $wm, $expected, 'small file parsed correctly from path' );
is( $root, 'S1', 'root correctly identified in file' );

( $wm, $root ) = ( undef, undef );
open my $fh, '<', $WMEfile;
( $wm, $root ) = read_wm_file($fh);
cmp_deeply( $wm, $expected, 'small file parsed correctly from glob' );

#read the rest from the data section
( $wm, $root ) = ( undef, undef );
( $wm, $root ) = read_wm( text => $allData->{'small text'} );
cmp_deeply( $wm, $expected, 'small text parsed correctly' );
is( $root, 'S1', 'root correctly identified in text' );

( $wm, $root ) = read_wm( text => $allData->{'incomplete text'} );
$expected = eval( $allData->{'incomplete eval'} );
cmp_deeply( $wm, $expected, 'incomplete structure ignored' );
is( $root, 'S1', 'root correctly identified despite incomplete structure' );

__DATA__
@@ small_eval
{
	S1 => {
		foo => ['bar'],
		baz => ['boo'],
		link => ['S2'],
	},
	S2 => {
		faz => ['far'],
		boo => ['baz'],
		fuzz => ['buzz'],
	},
}

@@ small text
(S1 ^foo bar ^baz boo ^link S2)

(S2 ^faz far 
	^boo baz
	^fuzz buzz)

@@ incomplete text
(S1 ^foo bar ^baz boo ^link S2)
(S2 ^faz far ^boo baz ^fuzz buzz

@@ incomplete eval
{
	S1 => {
		#'#wmeval' => 'S1',
		foo => ['bar'],
		baz => ['boo'],
		link => ['S2'],
	},
}
