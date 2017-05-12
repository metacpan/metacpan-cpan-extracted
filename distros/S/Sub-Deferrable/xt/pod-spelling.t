#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for spell-checking POD" if $@;

set_spell_cmd('aspell list');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
ACKNOWLEDGEMENTS
Budney
deferrable
failsafe
queueing
