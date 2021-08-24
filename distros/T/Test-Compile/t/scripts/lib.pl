#!/usr/bin/perl

BEGIN {
    require strict;
    require warnings;
    require parent;
    require Test::Builder;
    require File::Spec;
    require IPC::Open3;
    require version;
    @INC = grep { $_ eq 'blib/lib' } @INC;
}
use Test::Compile;

sleep 1;
