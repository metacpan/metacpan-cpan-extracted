#!/usr/bin/perl -w -I../lib/
use strict;
use Remote::Use
  host => 'orion:',
  prefix => '/tmp/perl5lib/',
  command => 'rsync -aue ssh',
  cachefile => '/tmp/perl5lib/.orion.installed.modules',
;
use Trivial;

Trivial::hello();
