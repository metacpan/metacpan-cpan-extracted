#!/usr/bin/perl

# Test that our object works with Data::FormValidator
use Test::More;
use English qw( -no_match_vars );
use Object::WithParams;
use strict;
use warnings;

my @modules = qw/ Data::FormValidator /;

foreach my $module (@modules) {
    eval "use $module";
    if ( $EVAL_ERROR ) {
        plan( skip_all => "$module not available for testing" );
        exit 1;
    }
}

plan( tests => 1 );

my $owp = Object::WithParams->new;
$owp->param(
    first_name => 'Jaldhar',
    last_name  => 'Vyas',
    country    => 'USA',
    languages  => [qw/ Gujarati English Sanskrit /],
);

my $expected = { 
    first_name => 'Jaldhar',
    last_name  => 'Vyas',
    country    => 'USA',
    languages  => [qw/ gujarati english sanskrit /], 
};

my $results = Data::FormValidator->check($owp, {
    optional       => [qw/ country /],
    required       => [qw/ first_name last_name languages /],
    field_filters  => {
        languages => [qw/ lc /],
    }
});

is_deeply(scalar$results->valid, $expected, 'Data::FormValidator');

1;
