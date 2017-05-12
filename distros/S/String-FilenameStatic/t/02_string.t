#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;

use String::FilenameStatic ':all';


use Test::More tests => 6;



my $s = '/this/is/a/path/.any_file.html';



is( get_path($s), '/this/is/a/path', 'get_path' );

is( get_file($s), '.any_file.html', 'get_file' );

is( remove_trailing_slash("$s/"), $s, 'remove_trailing_slash' );
is( remove_trailing_slash("$s"), $s, 'remove_trailing_slash' );

is( get_file_extension($s), 'html', 'get_file_extension' );

is( get_filename($s), '.any_file', 'get_filename' );



1;
