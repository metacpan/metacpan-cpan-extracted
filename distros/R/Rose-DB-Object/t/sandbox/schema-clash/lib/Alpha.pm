#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

package Alpha;

{   package Alpha::DB;
    use base qw( Rose::DB );

    __PACKAGE__->use_private_registry;
    __PACKAGE__->default_type( 'main' );
    __PACKAGE__->default_domain( 'test' );
    __PACKAGE__->register_db(
        domain   => 'test',
        type     => 'main',
        driver   => 'mysql',
        host     => 'localhost',
        database => 'alpha',
        username => 'alpha',
        password => 'alphapass',
    );
}

use Rose::DB::Object::Loader;

Rose::DB::Object::Loader->new(
    db           => Alpha::DB->new,
    class_prefix => "Alpha::",
)->make_classes;

1;
