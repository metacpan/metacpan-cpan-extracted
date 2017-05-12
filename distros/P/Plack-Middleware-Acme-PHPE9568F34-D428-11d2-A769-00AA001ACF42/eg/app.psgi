#!/usr/bin/env perl

use Plack::Builder;
my $app = sub {
    my $env = shift;
    return [ 200, ['Contet-Type' => 'text/html'], [ 'Hello World' ] ]
};

builder {
   enable 'Plack::Middleware::Acme::PHPE9568F34::D428::11d2::A769::00AA001ACF42';
   $app
}
