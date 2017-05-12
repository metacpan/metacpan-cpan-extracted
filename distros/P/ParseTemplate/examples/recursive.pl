#!/usr/local/bin/perl -w

require 5.004;

use strict;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;
				# recursive calls
print Parse::Template->new(
			   'TOP' => q!%%$_[0] < 10 ? '[' . TOP($_[0] + 1) . ']' : ''%%!
			  )->eval('TOP', 0);

