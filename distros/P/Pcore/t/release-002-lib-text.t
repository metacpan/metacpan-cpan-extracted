#!/usr/bin/env perl

package main;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for release candidate testing' );
    }
}

use Pcore;
use Test::More;

our $TESTS = 12;

plan tests => $TESTS;

my $BUF     = "   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     ";
my $CUT_BUF = "\n\n\n   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     \n\n\n";

ok( P->text->trim($BUF) eq "\n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n",       'trim' );
ok( P->text->ltrim($BUF) eq "\n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     ", 'ltrim' );
ok( P->text->rtrim($BUF) eq "   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n",   'rtrim' );

ok( P->text->trim_multi($BUF) eq "\n1\n2   3\n4\n5  6\n7\n\n\n\n9\n",              'trim_multi' );
ok( P->text->ltrim_multi($BUF) eq "\n1   \n2   3   \n4    \n5  6  \n7\n\n\n\n9\n", 'lrim_multi' );
ok( P->text->rtrim_multi($BUF) eq "\n1\n2   3\n    4\n   5  6\n  7\n\n\n\n  9\n",  'rtrim_multi' );

ok( P->text->cut($CUT_BUF) eq "   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n   \n  9\n     ",          'cut' );
ok( P->text->lcut($CUT_BUF) eq "   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     \n\n\n", 'lcut' );
ok( P->text->rcut($CUT_BUF) eq "\n\n\n   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     ", 'rcut' );

ok( P->text->cut_all($CUT_BUF) eq "1\n2   3\n4\n5  6\n7\n9",                                                   'cut_all' );
ok( P->text->lcut_all($CUT_BUF) eq "1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9\n     \n\n\n", 'lcut_all' );
ok( P->text->rcut_all($CUT_BUF) eq "\n\n\n   \n1   \n2   3   \n    4    \n   5  6  \n  7\n    \n\n   \n  9",   'rcut_all' );

done_testing $TESTS;

1;
__END__
=pod

=encoding utf8

=cut
