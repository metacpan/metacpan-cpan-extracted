#! /usr/bin/env perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok("Parse::Matroska::Utils", qw{uncamelize});
}

note "Hopefully 'uniq' works as is. It's copy-pasted from List::MoreUtils :F";

is uncamelize("SimpleString"), "simple_string", "Can uncamelize simple strings";
is uncamelize("ABCD"), "abcd", "uncamelize keeps acronyms";
is uncamelize("ABCDe"), "abcde", "uncamelize doesn't split on single lowercase";
is uncamelize("ABCDefgh"), "abc_defgh", "uncamelize knows where to split words";
is uncamelize("ABCDeFGH"), "abcde_fgh", "uncamelize keeps single lowercase as part of previous word";
is uncamelize("ABCDefGH"), "abc_def_gh", "uncamelize can split words followed by acronyms";
