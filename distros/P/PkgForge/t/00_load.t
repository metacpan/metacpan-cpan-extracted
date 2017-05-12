#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use_ok( 'PkgForge::Utils' );

use_ok( 'PkgForge::Types' );

use_ok( 'PkgForge::SourceUtils' );

use_ok( 'PkgForge::Source::SRPM' );

use_ok( 'PkgForge::Job' );

use_ok( 'PkgForge::App' );

use_ok( 'PkgForge::App::Submit' );

done_testing;
