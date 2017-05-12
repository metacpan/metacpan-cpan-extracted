#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use Test::More;
use Try::Tiny;

my @modules;

find ({no_chdir => 1,
       wanted => sub {
           return unless m/\.pm$/;
           push @modules, $File::Find::name
       }}, "lib");

for my $file (sort @modules) {
    try {
        ok (require $file, "Making sure $file is loadable");
    } catch {
        fail "Making sure $file is loadable";
    }
}

done_testing;
