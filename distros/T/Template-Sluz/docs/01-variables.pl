#!/usr/bin/env perl

use strict;
use warnings;
use Template::Sluz;

###############################################################################

my $s = Template::Sluz->new();

$s->assign('name'   , "Jason");                           # Scalar
$s->assign('colors' , ['red','green', 'blue']);           # Array
$s->assign('info'   , { age => 17, animal => 'kitten' }); # Hash

print $s->fetch();

__DATA__
My name is {$name}

Color : {$colors.0}
Animal: {$info.animal}
