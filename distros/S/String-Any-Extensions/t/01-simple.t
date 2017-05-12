#!perl
use 5.006;
use strict;
use warnings;
use String::Any::Extensions qw/exclude extension include/;
use Test::More tests => 12;

is( include( 'some/string/to.test', [ '.testo', '.test2', '.test' ] ), 1, 'simple include test' );

is( include( 'some/string/to.test', [ '.testo', '.test2', ] ), 0, 'negative include test' );

is( exclude( 'some/string/to.test', [ '.testo', '.test2', '.test' ] ), 0, 'simple exclude test' );

is( exclude( 'some/string/to.test', [ '.testo', '.test2' ] ), 1, 'negative exclude test' );

is( extension('some/string/to.test'), '.test', 'simple extension test' );

isnt( extension('some/string/to.test'), 'test', 'negative extension test' );

is( extension('.some/string/to.test'), '.test', 'extension test for hidden directory' );

is( extension('path/to/foo.mp3'), '.mp3', 'check for case insensitive' );

is( extension('path/to/foo.MP3'), '.MP3', 'check for case insensitive' );

is( extension('path/to/foo.jpeg'), '.jpeg', 'check for case insensitive' );

is( extension('path/to/foo.JPG'), '.JPG', 'check for case insensitive' );

is( extension('path/to/foo.tar.gz'), '.tar.gz', 'check for double extensions' );

