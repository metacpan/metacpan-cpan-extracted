use strict;
use warnings;
use Test::More tests => 4;
use String::Template;

is(expand_string('...<missing field>...', {}),
                 '......');

is(expand_string('...<missing field>...', {}, 1),
                 '...<missing field>...');

is(expand_string('...<missing%02d>...', {}),
                 '......');

is(expand_string('...<missing%02d>...', {}, 1),
                 '...<missing%02d>...');
