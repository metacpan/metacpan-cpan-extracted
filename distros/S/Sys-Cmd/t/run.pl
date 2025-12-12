#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
#use Log::Any::Adapter ('Stdout');
use Sys::Cmd qw[run];

print run('t/info.pl');
