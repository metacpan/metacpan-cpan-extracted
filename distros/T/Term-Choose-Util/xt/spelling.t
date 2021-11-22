use 5.10.0;
use strict;
use warnings;
use Test::More;

use Test::Spelling;


set_spell_cmd('aspell list -l en -p /dev/null');

add_stopwords( <DATA> );

all_pod_files_spelling_ok( 'lib' );



__DATA__
Kiem
Matthäus
maxcols
stackoverflow
pwd
dir
de
Dirs
SpaceBar
TUI
DEPRECATIONS
