#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;
use Pod::Trac;

use_ok('Pod::Trac');
can_ok('Pod::Trac', 'init');
can_ok('Pod::Trac', 'generate');
can_ok('Pod::Trac', 'write_to_trac');
can_ok('Pod::Trac', 'from_file');
can_ok('Pod::Trac', 'from_path');

