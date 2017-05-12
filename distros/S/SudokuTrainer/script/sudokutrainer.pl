#!/usr/bin/perl
use strict;
use warnings;
#use feature qw( say );

package main;

use version; our $VERSION = qv('0.04');    # PBP

use Games::Sudoku::Trainer::Run;
main::init_all();

Tk::MainLoop();

