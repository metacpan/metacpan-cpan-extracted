#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name', "Jill");

print $s->fetch();

__DATA__
{literal}Special chars: { } {$name}{/literal}

Note: delimiters { or } surrounded by whitespace are NOT treated as a template
delimiter — it passes through as-is:

sub foo(num) { return num + 6; }
