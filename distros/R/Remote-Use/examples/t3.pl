#!/usr/bin/perl -w -I../lib/
use strict;

require Remote::Use;
Remote::Use->import(
  host => 'http://orion.pcg.ull.es/~casiano/cpan',
  prefix => '/tmp/perl5lib/',
  command => 'wget -v',
  commandoptions => '-O',
  ppmdf => '/tmp/perl5lib/.orion.via.web',
);

require Tintin::Trivial;
Tintin::Trivial::hello();

