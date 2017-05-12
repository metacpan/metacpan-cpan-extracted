#!/bin/sh

cover --delete
PERL5OPT=-MDevel::Cover=+select_re,Router,+ignore,.*\.t,-ignore,prove prove t -r
cover

