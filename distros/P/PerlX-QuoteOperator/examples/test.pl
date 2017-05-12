#!/usr/bin/env perl

use strict;
use warnings;

# old style
#use PerlX::QuoteOperator qwuc => [ qw => sub (@) { @_ } ];

# new style
use PerlX::QuoteOperator quc => { -emulate => 'qq', -with => sub ($) { uc $_[0] } };
print quc{this will be all in upper case};

print "\n";

