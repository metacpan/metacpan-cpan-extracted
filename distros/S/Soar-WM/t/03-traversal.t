#test that slurping is done correctly

use strict;
use warnings;
use Test::More tests => 13 + 1;    #+ 1 for NoWarnings auto-test
use Test::NoWarnings;
use Test::Deep;

use Soar::WM qw(wm_root wm_root_from_file);
use FindBin('$Bin');
use File::Spec;
use Data::Section::Simple qw(get_data_section);
use Data::Dumper;

my $class   = 'Soar::WM::Element';
my $allData = get_data_section;

#example WME dump is held in the t/data folder
my $WMEfile = File::Spec->catfile( $Bin, 'data', 'wmedumpSmall.txt' );
my $root = wm_root_from_file($WMEfile);

isa_ok( $root, $class );
is( $root->id, 'S1', 'Root identified correctly from file' );

my $wmText = $allData->{'small text'};
$root = wm_root( text => $wmText );
isa_ok( $root, $class );
is( $root->id, 'S1', 'Root identified correctly from text' );

is(scalar @{ $root->children('links_only' => 1) }, 2, 'link children only');
is(scalar @{ $root->children() }, 5, 'link children only');

is( $root->num_links, 2, 'Root should have two WME links' );
my @atts = @{ $root->atts() };
is( @atts, 3, 'Three attributes found' );

my @links = @{ $root->vals('link') };
is( @links, 2, 'Two values for link' );

my @foos = @{ $root->vals('foo') };
is( @links, 2, 'Two values for foo' );
my $foo = $root->first_val('foo');
is( $foo, 'bar', 'First value of \'foo\' is \'bar\'' );

my $val = $root->first_val('link');
isa_ok( $val, $class );
my $val2 = $val->first_val('faz');
is( $val2, 'far', 'Correct value' );

__DATA__
@@ small text
(S1 ^foo bar ^foo buzz ^baz boo ^link S2 ^link S3)
(S2 ^faz far 
	^boo baz
	^fuzz buzz)
(S3 ^junk foo)
