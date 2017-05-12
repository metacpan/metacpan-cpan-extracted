#!/usr/bin/perl -w -I../lib/
use strict;
require Remote::Use;
Remote::Use->import(
  host => 'http://orion.pcg.ull.es/~casiano/cpan',
  prefix => '/tmp/perl5lib',
  command => 'wget -o /tmp/wget.log',
  commandoptions => '-O',
  cachefile => '/tmp/perl5lib/.orionhttp.installed.modules',
);

require Trivial;
Trivial::hello();
