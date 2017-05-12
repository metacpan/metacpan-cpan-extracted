use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }

use Test::Spellunker;

add_stopwords("dankogai");

load_dictionary(\*DATA);

all_pod_files_spelling_ok();

__DATA__
foo
bar
