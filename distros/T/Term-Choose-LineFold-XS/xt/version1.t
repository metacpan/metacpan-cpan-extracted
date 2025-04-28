use 5.16.0;
use strict;
use warnings;
use Test::More;


use Test::Version qw( version_ok ), {
#    is_strict   => 1,
    has_version => 1,
};

#version_all_ok( 'lib' );

version_ok( 'lib/Term/Choose/LineFold/XS.pm' );

done_testing;
