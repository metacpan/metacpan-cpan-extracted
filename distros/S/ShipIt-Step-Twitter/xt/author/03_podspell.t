#!perl -w

use strict;
use warnings;
use Test::Spelling;
use utf8;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
API
CPAN
Grünauer
Marcel
ShipIt
YAML
behaviour
chomps
distname
github
init
op
pipe's
placeholders
ref
segment's
shipit
unshifts
username
whitelist
whitelists
yml
