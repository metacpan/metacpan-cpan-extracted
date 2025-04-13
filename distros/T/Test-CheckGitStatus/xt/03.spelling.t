#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Test::Spelling;
use Pod::Wordlist;

add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( lib ) );

__DATA__
Müller
untracked
worktree
