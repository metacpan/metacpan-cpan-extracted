#test that slurping is done correctly

use strict;
use warnings;
use Test::More tests => 4;
use Test::Warn;
use Data::Section::Simple qw(get_data_section);
use Soar::WM qw(wm_root wm_root_from_file);

warning_is { wm_root_from_file }{ carped => 'missing file name argument' },
  'requires filename arg';

my $allData = get_data_section;
my $wmText  = $allData->{'small'};
my $root    = wm_root( text => $wmText );
warning_is { $root->vals }{ carped => 'missing argument attribute name' },
  'requires query arg';
warning_is { $root->first_val }{ carped => 'missing argument attribute name' },
  'requires query arg';

warning_is { Soar::WM::Element->new( $root->{wm}, 'Z9' ) }
{ carped => 'Given ID doesn\'t exist in given working memory' },
  "Can't create new from non-existent WME";

__DATA__
@@ small
(S1 ^foo bar ^foo buzz ^baz boo ^link S2 ^link S3)
(S2 ^faz far 
	^boo baz
	^fuzz buzz)
(S3 ^junk foo)
