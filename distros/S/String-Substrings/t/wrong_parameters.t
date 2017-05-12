#!/usr/bin/perl

use String::Substrings;
use Test::Exception;

use Test::More tests => 6;

dies_ok {substrings ["aa"]}         "Array reference as argument";
dies_ok {substrings {"aa" => "bb"}} "Hash reference as argument";
dies_ok {substrings "A string", ["aa"]} "Array reference as length";
dies_ok {substrings "A string", {aa => "bb"}} "Hash reference as length";
dies_ok {substrings "A string", "three"} "String as length";
dies_ok {substrings "A string", -1} "Negative length";
