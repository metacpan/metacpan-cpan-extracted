#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'Class to handle simple logical set unions and intersections.',
               NAME         => 'Set::Definition',
               VERSION_FROM => 'Definition.pm',
               PREREQ_PM    => {
               }
             );
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}

WriteMakefile( @basics );
