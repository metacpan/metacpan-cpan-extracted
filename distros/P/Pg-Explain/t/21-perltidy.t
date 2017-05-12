#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::PerlTidy; import Test::PerlTidy; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Tidy required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perltidyrc' );
run_tests(
    perltidyrc => $rcfile,
    exclude    => [ qr{\.t$}, qr{^blib/}, ],
);
