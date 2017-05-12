#!/usr/bin/perl -w

BEGIN {
  push @INC , '../';  
  push @INC , '../SVG';
}

use strict;
use SVG;


my $svg  = SVG->new();

my $def  = $svg->defs( id => 'myStar' );

my $r_star_path = $svg->get_path(type=>'path',x=>[-0.951,0.951,-0.588,0.000,0.588],y=>[-0.309,-0.309,-0.809,-1.000,0.809],-closed=>1);

my $star = $def->path('transform' => "scale(100, 100)",%$r_star_path,);

$svg->use(-href => "#myStar", stroke=>"red",fill => "yellow", transform => "translate(200, 200)" );

print "Content-Type: image/svg+xml\n\n";

print $svg->xmlify;

