#!/usr/bin/perl -w

use strict;
use Perl::Visualize qw/etch paint/;

etch "larry.gif", "larrysig.gif", 'print "This is Larry Wall\n"';
etch "nagra.gif", "nagraview.gif", 'exec "/usr/bin/display $0"';
paint "damian.gif", "poetic-damian.gif", <<EOF;
use Coy;
Recite war "poetry";
EOF
