#!/usr/bin/env perl

use Test::More tests => 6;

use_ok('Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach');

for my $method (qw/
    applies_to
    default_severity
    default_themes
    supported_parameters
    violates
/) {

    can_ok(
        'Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach',
        $method
    );
}
