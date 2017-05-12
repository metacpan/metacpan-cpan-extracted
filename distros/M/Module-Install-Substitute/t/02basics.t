#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::File::Contents;

use_ok( 'Module::Install::Substitute' );

my $obj = new Module::Install::Substitute;
isa_ok($obj, 'Module::Install::Substitute');

$obj->substitute( { TEST => 'bar'}, 't/data/input/02basics/inline' );
file_contents_identical('t/data/input/02basics/inline', 't/data/output/02basics/inline1' );
$obj->substitute( { TEST => 'zoo'}, 't/data/input/02basics/inline' );
file_contents_identical('t/data/input/02basics/inline', 't/data/output/02basics/inline2' );

$obj->substitute( { TEST => 'bar'}, { sufix => '.in' }, 't/data/input/02basics/sufix' );
file_contents_identical('t/data/input/02basics/sufix', 't/data/output/02basics/inline1' );
$obj->substitute( { TEST => 'zoo'}, { sufix => '.in' }, 't/data/input/02basics/sufix' );
file_contents_identical('t/data/input/02basics/sufix', 't/data/output/02basics/inline2' );

mkdir 't/data/input/02basics/to' unless -d 't/data/input/02basics/to';
$obj->substitute( { TEST => 'bar'},
                  { from => 't/data/input/02basics/from', to => 't/data/input/02basics/to'  },
                  'inline'
                );
file_contents_identical('t/data/input/02basics/to/inline', 't/data/output/02basics/inline1' );
$obj->substitute( { TEST => 'zoo'},
                  { from => 't/data/input/02basics/from', to => 't/data/input/02basics/to'  },
                  'inline'
                );
file_contents_identical('t/data/input/02basics/to/inline', 't/data/output/02basics/inline2' );

