#!/usr/bin/perl

use strict;
use warnings;

use Ruby -all;


Symbol
	->all_symbols
	->map(sub{ $_[0]->to_s })
	->sort()
	->each(sub{ puts $_[0] });
