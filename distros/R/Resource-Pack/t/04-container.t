#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

use Resource::Pack::Resource;

{
    my $container = Resource::Pack::Resource->new(
        name         => 'test',
        install_from => data_dir,
    );
    $container->add_file(
        name => 'test1',
        file => 'test.txt'
    );
    $container->add_file(
        name => 'test2',
    );

    test_install($container, 'test.txt', 'test2');
}

done_testing;
