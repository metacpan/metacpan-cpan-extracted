#!/usr/bin/perl
use strict;
use warnings;

use Plack::Builder;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;


my $app = sub {
    my $env = shift;
    return [
        200,
        [ 'Content-Type', 'text/html' ],
        [
            '<html><head><title>test app</title></head><body><h1>test app</h1><pre>',
            Dumper( $env ),
            '</pre></body></html>'
        ]
    ];
};


return builder {
    enable 'Debug', panels => [ qw( Environment Response ) ];
    enable 'Debug::Notepad', notepad_file => 'foo';
    $app;
};

