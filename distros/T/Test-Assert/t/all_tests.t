#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Test::Unit::Lite 0.11;
use Test::Assert;

use Exception::Base max_arg_nums => 0, max_arg_len => 200, verbosity => 4;
use Exception::Assertion verbosity => 4;

local $SIG{__WARN__} = sub { require Carp; Carp::confess( $_[0] ) };

Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');
