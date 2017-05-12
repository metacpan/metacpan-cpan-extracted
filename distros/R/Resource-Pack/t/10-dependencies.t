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
        name         => 'test2',
        dependencies => ['test1'],
    );

    test_install($container->fetch('test2'), 'test.txt', 'test2');

    $container->add_file(
        name         => 'test3',
        dependencies => ['test2'],
    );

    test_install($container->fetch('test3'), 'test.txt', 'test2', 'test3');

    $container->add_dir(
        name => 'test4',
    );

    $container->add_url(
        name         => 'jquery',
        url          => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js',
        dependencies => ['test1', 'test2', 'test4'],
    );

    test_install($container->fetch('jquery'),
                 sub { ok(!-e 'test3', "test3 wasn't installed"); },
                 'test.txt', 'test2', file('test4', 'file'),
                 'jquery.min.js');

    my $outer_container = Resource::Pack::Resource->new(
        name         => 'outer',
        install_from => data_dir,
    );
    $outer_container->add_sub_container($container);
    $outer_container->add_file(
        name => 'test5',
    );
    $outer_container->add_dir(
        name => 'test6',
        dependencies => ['test/test3'],
    );

    test_install($outer_container->fetch('test6'),
                 sub {
                     ok(!-e 'test4',         "test4 wasn't installed");
                     ok(!-e 'test5',         "test5 wasn't installed");
                     ok(!-e 'jquery.min.js', "jquery wasn't installed");
                 },
                 'test.txt', 'test2', 'test3', file('test6', 'file'));
}

done_testing;
