use lib 't', 'lib';
use strict;
use warnings;
use Test::More;

eval "use Encode";
my $enc = ! $@;

use Spoon::ContentObject;

plan tests => 8;

my $database_directory;

{
    no warnings;

    package Spoon::ContentObject;

    sub database_directory { $database_directory }

    undef &Spoon::ContentObject::content;
    field 'content';
}

{
    $database_directory = 't/content';

    my $object = Spoon::ContentObject->new(id => 'test1');
    $object->load_content;

    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8( $object->content ), 'object content is utf8' );
    }

    is( $object->content, "This file has no utf8 in it.\n",
        'test content was loaded' );

    io->dir('t/tmp')->mkpath;

    $database_directory = 't/tmp';
    $object->force(1);
    $object->store_content;

    $object->load_content;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8( $object->content ), 'object content is utf8 after save/load' );
    }
    is( $object->content, "This file has no utf8 in it.\n",
        'test content was loaded after save/load' );
}

{
    $database_directory = 't/content';

    my $object = Spoon::ContentObject->new(id => 'test2');
    $object->load_content;

    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8( $object->content ), 'object content is utf8' );
    }

    is( $object->content, "This file has utf8 in it - \x{16A0}\x{16C7}\x{16BB}.\n",
        'test content was loaded' );

    io->dir('t/tmp')->mkpath;

    $database_directory = 't/tmp';
    $object->force(1);
    $object->store_content;

    $object->load_content;

    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8( $object->content ), 'object content is utf8 after save/load' );
    }

    is( $object->content, "This file has utf8 in it - \x{16A0}\x{16C7}\x{16BB}.\n",
        'test content was loaded after save/load' );
}
