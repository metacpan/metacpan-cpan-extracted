#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

use Resource::Pack::File;

like(
    exception {
        Resource::Pack::File->new(name => 'test', file => 'test.txt')
    },
    qr/install_from is required/,
    "install_from is required for lone Files"
);

{
    my $file = Resource::Pack::File->new(
        name         => 'test',
        file         => 'test.txt',
        install_from => data_dir,
    );

    test_install($file, 'test.txt');
}

{
    my $file = Resource::Pack::File->new(
        name         => 'test',
        install_from => data_dir,
    );

    test_install($file, 'test');
}

done_testing;
