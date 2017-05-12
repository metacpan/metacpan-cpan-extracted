#!/usr/bin/perl -w -I../lib/
use strict;
require Remote::Use;
Remote::Use->import(config => 'wgetconfig');
require Trivial;

Trivial::hello();
