#!/usr/bin/env perl
use warnings;
use strict;
use List5;

unshift @ARGV, '--noslurp';
List5->new->main("Try inputs 'c' and 'cc': ");

sub TERMINAL::info {
  $_[0]->attr;
}
