use 5.16.0;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage::TrustMe;
use Pod::Coverage::TrustMe;

use lib 'lib';
use Term::Choose::LineFold::XS;

plan tests => 1;
pod_coverage_ok( 'Term::Choose::LineFold::XS', { export_only => 1 } );
