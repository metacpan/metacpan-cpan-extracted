#!/usr/bin/perl -w -I../lib/
use strict;
require Remote::Use;
Remote::Use->import(config => 'lwpmirrorconfig');
require Trivial;

Trivial::hello();
