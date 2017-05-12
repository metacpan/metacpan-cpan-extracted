#!/usr/bin/perl --  ========================================== -*-perl-*-
#
# t/00-latex.t
#
# Test the Template::Latex module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Test::More tests => 14;
use lib ( abs_path("$Bin/../lib") );
use constant TL => 'Template::Latex';

#------------------------------------------------------------------------
# test methods to get/set paths
#------------------------------------------------------------------------

use_ok('Template::Latex');
ok( TL->latex_path('/path/to/latex'), 'set latex path' );
is( TL->latex_path(), '/path/to/latex', 'get latex path' );

ok( TL->pdflatex_path('/path/to/pdflatex'), 'set pdflatex path' );
is( TL->pdflatex_path(), '/path/to/pdflatex', 'get pdflatex path' );

ok( TL->dvips_path('/path/to/dvips'), 'set dvips path' );
is( TL->dvips_path(), '/path/to/dvips', 'get dvips path' );

my $paths = TL->latex_paths();
is( ref $paths, 'HASH', 'got paths' );
is( $paths->{ latex    }, '/path/to/latex',    'paths latex'    );
is( $paths->{ pdflatex }, '/path/to/pdflatex', 'paths pdflatex' );
is( $paths->{ dvips    }, '/path/to/dvips',    'paths dvips'    );

TL->latex_paths({
    latex    => '/new/path/to/latex',
    pdflatex => '/new/path/to/pdflatex',
    dvips    => '/new/path/to/dvips',
});

is( TL->latex_path(),    '/new/path/to/latex',    'new latex'    );
is( TL->pdflatex_path(), '/new/path/to/pdflatex', 'new pdflatex' );
is( TL->dvips_path(),    '/new/path/to/dvips',    'new dvips'    );




