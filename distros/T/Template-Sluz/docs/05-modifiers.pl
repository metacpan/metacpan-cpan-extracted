#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name' , "jason");
$s->assign('greeting', "<b>Hi</b>");

print $s->fetch();

__DATA__
Original: {$name}
Uppercase: {$name|uc}
Lowercase: {$name|lc}
Capitalized: {$name|ucfirst}

Escaped: {$greeting|escape}
Chained: {$name|ucfirst|escape}
