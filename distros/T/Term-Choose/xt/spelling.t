use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Spelling;

set_spell_cmd('aspell list -l en -p /dev/null');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();


__DATA__
BackSpace
Ctrl
de
EOT
hjkl
Kiem
lf
ll
markable
Matthäus
noncharacter
OEM
PageDown
PageUp
preselection
preselected
preselects
ReadKey
selectable
SGR
SpaceBar
stackoverflow
