# check that a TBX::Min object can be serialized as a TBX-Min XML file

use strict;
use warnings;
use Test::More 0.88;
plan tests => 2;
use Test::NoWarnings;
use TBX::Min;
use Test::XML;
use FindBin qw($Bin);
use Path::Tiny;

my $basic_path = path($Bin, 'corpus', 'min.tbx');
my $basic_txt = $basic_path->slurp;

my $min = TBX::Min->new_from_xml($basic_path);

my $new_xml = ${ $min->as_xml };

is_xml($new_xml, $basic_txt, 'TBX input and output match');
