#!/usr/local/bin/perl -w

require 5.004;

use strict;
#use diagnostics;
use Carp;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;
$|++;
$Parse::Template::CONFESS = 1;
Parse::Template->new(
		     #'TOP' => q!%%$_[0] < 10 ? '[' . TOP($_[0] + 1) . ']' : '' %%!
		     #'TOP' => q!%%$_[0] < 10 ? '[' . TOP($_[0] + 1) . ']' : Carp::confess() %%!
		     'TOP' => q!%%$_[0] < 1 ? '[' . TOP($_[0] + 1) . ']' : die() %%!
		    )->eval('TOP', 0);

