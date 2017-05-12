#!/usr/bin/perl
use warnings;
use strict;

use blib;
use OOP::Perlish::Class::AutoTest (tests => [ 'UnitTests' ], package => 'OOP::Perlish::Class::Accessor', exclude => [ '^Base.pm$' ]);
OOP::Perlish::Class::AutoTest->runtests();
