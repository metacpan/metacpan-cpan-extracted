package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Autoconf
charnames
errstr
hocery
indices
infeasible
instantiation
jb
kluginess
lexed
lexes
merchantability
nav
navigational
perlrecharclass
perluniprops
POSIX
postderef
postfix
PPI
ppi
PPI's
reblesses
repl
schild
schildren
scontent
subclasses
subscripted
TODO
tokenization
Tokenize
tokenize
tokenized
tokenizer's
TOKENIZERS
tokenizers
tokenizes
tokenizing
trigraphs
Un
unicode
unterminated
UTF
version's
Wyant
XS
