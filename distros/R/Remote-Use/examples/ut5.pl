#!/usr/bin/perl -w -I../lib/
use strict;
use Remote::Use
  command => 'wget -o /tmp/wget.log',
  commandoptions => '-O',
  host => 'http://orion.pcg.ull.es/~casiano/cpan', 
  prefix => '/tmp/perl5lib/',
  ppmdf => '/tmp/perl5lib/.orion.via.web',
;
use Tintin::Trivial;
use Trivial;

Trivial::hello();
Tintin::Trivial::hello();

