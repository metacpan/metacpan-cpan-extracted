#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use ExtUtils::Manifest;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

plan tests => 1;
is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
