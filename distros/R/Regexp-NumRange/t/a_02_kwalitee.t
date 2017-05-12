#!perl

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
    exit 0;
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };
 
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

