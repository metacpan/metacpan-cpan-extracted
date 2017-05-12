#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MooseX::Compile::Base';
use ok 'MooseX::Compile::Compiler';

# don't import
BEGIN { require_ok 'MooseX::Compile::Bootstrap' }
BEGIN { require_ok 'MooseX::Compile' };


