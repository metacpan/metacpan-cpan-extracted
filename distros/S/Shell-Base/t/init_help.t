#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 3;

use_ok("Shell::Base");

my $sh = Shell::Base->new();
my @helps = $sh->helps();

is(scalar @helps, 1, "Found 1 help method");

# Create a new help method, in an eval so that it
# isn't present when the above runs
eval "
package Shell::Base;
sub help_me {
    'lala'
}
";

# Re-initialize helps...
$sh->init_help();

@helps = $sh->helps();
is(scalar @helps, 2, "Found 2 help methods");
