use strict;
use Test::More;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Path';
use Image::SVG::Transform;
use Image::SVG::Path qw/extract_path_info/;
use JSON qw/to_json/;

my $suspect_path =<<EOSVG;
M 0,5 L 0,6 m 1,0 1,0 0,1 -1,0 z m 2,0 1,0 0,1 -1,0 z
EOSVG

#M 138,11
#L 139,12
#m -91,31 5,5 -3,3 -5,-5 z
#m 7,7 5,5 -3,3 -5,-5 z
#m 7,7 5,5 -3,3 -5,-5 z
#m 125,38 3,3 7,-7 -3,-3 z
#m 39,-39 3,3 7,-7 -3,-3 z
#m 31,-31 3,3 7,-7 -3,-3 z
#EOSVG

{
    my @path_info = extract_path_info($suspect_path, {absolute => 1, no_shortcuts => 1});
    diag to_json(\@path_info, { pretty => 1, });
}

done_testing();
