#!/usr/bin/perl

BEGIN {
    require strict;
    require warnings;
    require Test::Builder;
    require File::Spec;
    require UNIVERSAL::require;
    require version;
    @INC = grep { $_ eq 'blib/lib' } @INC;
}
use Test::Compile;

sleep 1;
