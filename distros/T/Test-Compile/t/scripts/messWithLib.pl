#!/usr/bin/perl

BEGIN {
    require strict;
    require warnings;
    require parent;
    require Test::Builder;
    require File::Find;
    require File::Spec;
    require IPC::Open3;
    require version;
    @INC = grep { $_ =~ m/blib.lib/ } @INC;
}
use Test::Compile;

sleep 1;
