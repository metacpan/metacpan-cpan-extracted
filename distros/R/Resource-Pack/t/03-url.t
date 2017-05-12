#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

use Resource::Pack::URL;

{
    my $url = Resource::Pack::URL->new(
        name => 'jquery',
        url  => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js',
    );
    test_install(
        $url,
        sub {
            like(file('jquery.min.js')->slurp,
                 qr/jQuery JavaScript Library/,
                 "got jquery");
        },
        'jquery.min.js',
    );
}

done_testing;
