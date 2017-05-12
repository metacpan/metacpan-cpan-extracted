#!perl -w
use strict;
use warnings;
use Test::Spelling;
use Pod::Wordlist::hanekomu;

add_stopwords("Coppit", "Gr\xFCnauer");

all_pod_files_spelling_ok('lib');
