use strict;
use Test::More;
use Test::Exception;
my $t; use lib ($t = -e 't' ? 't' : '.');
use lib 'lib', '../lib';

use_ok 'SVG::Estimate';
dies_ok {
    my $onesquare = SVG::Estimate->new( file_path => $t.'/var/onesquare_with_units.svg' );
    $onesquare->estimate;
} 'estimate dies when an SVG element has a % sign in it';

use_ok 'SVG::Estimate';
dies_ok {
    my $onesquare = SVG::Estimate->new( file_path => $t.'/var/onesquare_with_units_transform.svg' );
    $onesquare->estimate;
} 'estimate dies when an SVG element has a % sign in it';

done_testing();

