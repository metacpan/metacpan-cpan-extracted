use 5.10.1;
use strict;
use warnings;
use Test::More;

use Test::Spelling;

#set_spell_cmd('aspell list -l en -p /dev/null');
set_spell_cmd('hunspell -l -d en_US');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();


__DATA__
BackSpace
Kiem
Matthäus
stackoverflow
reinit_encoding
compat
ascii
ro
de
OEM
MSWin32
doesn
