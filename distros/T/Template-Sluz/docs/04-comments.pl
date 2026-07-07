#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name', "Jason");

print $s->fetch();

__DATA__
Hello {$name}!

{* This is a comment and will not be rendered *}

My name is {$name}.
