#!/usr/bin/perl

use strict;
use warnings;

use String::Tagged::Terminal;

sub do_one
{
   my ( $name, $value ) = @_;

   my $st = String::Tagged::Terminal->new( "An example of $name" );
   $st->apply_tag( 14, -1, $name => $value );

   $st->say_to_terminal;
}

do_one @$_ for
   [ bold    => 1 ],
   [ italic  => 1 ],
   [ under   => 1 ],
   [ strike  => 1 ],
   [ blink   => 1 ],
   [ reverse => 1 ],
   [ altfont => 1 ],
   [ fgindex => 4 ],
   [ bgindex => 2 ];
