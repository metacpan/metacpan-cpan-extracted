#!/usr/bin/perl -w -I../lib/
use strict;
use Remote::Use
  host => 'http://orion.pcg.ull.es/~casiano/cpan',
  command => 'wget -v -o /tmp/wget.log',
  commandoptions => '-O',
  prefix => '/tmp/perl5lib/',
  ppmdf => '/tmp/perl5lib/.orion.via.web',
;
use Tintin::Trivial;

Tintin::Trivial::hello();
