#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

package Beta;

{   package Beta::DB;
    use base qw( Rose::DB );

    __PACKAGE__->use_private_registry;
    __PACKAGE__->default_type( 'main' );
    __PACKAGE__->default_domain( 'test' );
    __PACKAGE__->register_db(
        domain   => 'test',
        type     => 'main',
        driver   => 'mysql',
        host     => 'localhost',
        database => 'beta',
        username => 'beta',
        password => 'betapass',
    );
}

use Rose::DB::Object::Loader;

Rose::DB::Object::Loader->new(
    db           => Beta::DB->new,
    class_prefix => "Beta::",
)->make_classes;

1;
