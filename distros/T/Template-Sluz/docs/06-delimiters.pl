#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name'  => "jason");
$s->assign('age'   => 21);

# Use angle brackets instead of curly braces
$s->set_delimiters('<', '>');

print $s->fetch();

__DATA__
Angle-bracket delimiters:

  Name: <$name>
   Age: <$age|uc> (modifier works too)
