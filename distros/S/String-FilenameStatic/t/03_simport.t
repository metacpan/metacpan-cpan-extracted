#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;

use String::FilenameStatic qw(get_path get_filename);


use Test::More tests => 2;



my $s = '/this/is/a/path/.any_file.html';



is( get_path($s), '/this/is/a/path', 'get_path' );

is( get_filename($s), '.any_file', 'get_filename' );



1;
