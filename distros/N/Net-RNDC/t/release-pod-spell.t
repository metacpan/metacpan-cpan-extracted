#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More;

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx; # skip comments, whitespace
}

add_stopwords(@stopwords);
local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok();

__DATA__
Matthew
Horsfall
alh
API
HMAC
RNDC
timestamp
IPv
TBD
TODO
nameserver
