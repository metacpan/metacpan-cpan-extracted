#!/usr/bin/perl

use Test::More tests => 1;
use Schedule::Cron;
use strict;

my @args = (
            [ "bla", "blub", { "deeper" => 1, "and" => {deeper => "stop" } } ],
            3,
          { "blub" => "bla", 3 => 2 }
           );     

my $out = join(",",Schedule::Cron->_format_args(@args));
like($out,qr/\['bla','blub',{.*?'and'\s*=>\s*'HASH\(.*?\)'.*?}\],3,{.*?'blub'\s*=>\s*'bla'.*?}/);
