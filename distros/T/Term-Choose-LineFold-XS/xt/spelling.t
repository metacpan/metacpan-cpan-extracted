use 5.16.0;
use strict;
use warnings;
use Test::More;

use Test::Spelling;

set_spell_cmd('aspell list -l en -p /dev/null');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();


__DATA__
Kiem
LineFold
Matthäus
