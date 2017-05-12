#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';
use Perl::Dist::Asset::Module;





#####################################################################
# Main Tests

my $module1 = Perl::Dist::Asset::Module->new(
	name => 'Params::Util',
);
isa_ok( $module1, 'Perl::Dist::Asset::Module' );
is( $module1->name,  'Params::Util', '->name ok'  );
is( $module1->force, 0,              '->force ok' );
