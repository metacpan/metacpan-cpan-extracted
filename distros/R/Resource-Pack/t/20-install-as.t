#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

use Resource::Pack::File;
use Resource::Pack::Dir;
use Resource::Pack::URL;

{
    my $file = Resource::Pack::File->new(
        name         => 'test',
        file         => 'test.txt',
        install_from => data_dir,
        install_as   => 'something_else.txt',
    );

    test_install($file, 'something_else.txt');
}

{
    my $dir = Resource::Pack::Dir->new(
        name         => 'test',
        dir          => 'css',
        install_from => data_dir,
        install_as   => 'custom_css',
    );

    test_install($dir, file('custom_css', 'style.css'));
}

{
    my $dir = Resource::Pack::Dir->new(
        name         => 'test',
        dir          => 'css',
        install_from => data_dir,
        install_as   => '',
    );

    test_install($dir, 'style.css');
}

{
    my $url = Resource::Pack::URL->new(
        name       => 'jquery',
        url        => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js',
        install_as => 'jquery.1.4.2.min.js',
    );
    test_install(
        $url,
        sub {
            like(file('jquery.1.4.2.min.js')->slurp,
                 qr/jQuery JavaScript Library/,
                 "got jquery");
        },
        'jquery.1.4.2.min.js',
    );
}

done_testing;
