#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('colors', ['red', 'green', 'blue']);

print $s->fetch();

__DATA__
My favorite colors:

{foreach $colors as $color}
- {$color}
{/foreach}
