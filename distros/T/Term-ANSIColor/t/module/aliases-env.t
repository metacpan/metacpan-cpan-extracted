#!/usr/bin/perl
#
# Test setting color aliases via the environment.
#
# Copyright 2012 Stephen Thirlwall
# Copyright 2012, 2014 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::RRA qw(use_prereq);

# Load prerequisite modules.
use_prereq('Test::Warn');

# Print out our plan.
plan tests => 19;

# Ensure we don't pick up a setting from the user's environment.
delete $ENV{ANSI_COLORS_DISABLED};

# Set up some custom color configuration.  The last four will produce warnings
# on module load.
my @COLOR_ALIASES = (
    ' custom_black = black',  'custom_red= red',
    'custom_green =green ',   'custom_blue=blue',
    'custom_unknown=unknown', '=no_new',
    'no_old=',                'no_equals',
    'red=green',              'custom_test=red=blue',
    'custom!test=red',
);
local $ENV{ANSI_COLORS_ALIASES} = join(q{,}, @COLOR_ALIASES);

# Load the module, which should produce those warnings.
my $require_sub = sub { require_ok('Term::ANSIColor') };
warnings_like(
    $require_sub,
    [
        qr{ \A Invalid [ ] attribute [ ] name [ ] "unknown" [ ] in [ ]
            "custom_unknown=unknown" [ ] at [ ] }xms,
        qr{ \A Bad [ ] color [ ] mapping [ ] "=no_new" [ ] at [ ]   }xms,
        qr{ \A Bad [ ] color [ ] mapping [ ] "no_old=" [ ] at [ ]   }xms,
        qr{ \A Bad [ ] color [ ] mapping [ ] "no_equals" [ ] at [ ] }xms,
        qr{ \A Cannot [ ] alias [ ] standard [ ] color [ ] "red" [ ] in
            [ ] "red=green" [ ] at [ ] }xms,
        qr{ \A Invalid [ ] attribute [ ] name [ ] "red=blue" [ ] in [ ]
            "custom_test=red=blue" [ ] at [ ] }xms,
        qr{ \A Invalid [ ] alias [ ] name [ ] "custom!test" [ ] in [ ]
            "custom!test=red" [ ] at [ ] }xms,
    ],
    'Correct warnings when loading module'
);

# Import the functions for convenience.
Term::ANSIColor->import(qw(color colored colorvalid uncolor));

# Check the custom colors all get assigned.  They use various spacing formats
# and should all parse correctly.
for my $original (qw(black red green blue)) {
    my $custom = 'custom_' . $original;
    ok(colorvalid($custom), "$custom is valid");
    is(color($custom), color($original),
        "...and matches $original with color");
    is(
        colored('test', $custom),
        colored('test', $original),
        "...and matches $original with colored"
    );
    is_deeply([uncolor(color($custom))],
        [$original], "...and uncolor returns $original");
}

# custom_unknown is mapped to an unknown color and should not appear.
is(colorvalid('custom_unknown'), undef, 'Unknown color mapping fails');
