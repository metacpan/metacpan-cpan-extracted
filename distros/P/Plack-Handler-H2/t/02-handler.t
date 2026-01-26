#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Plack::Handler::H2;
use File::Temp;

{
    my $handler = Plack::Handler::H2->new(
        host => 'localhost',
        port => 8443,
        ssl_cert_file => 'test.crt',
        ssl_key_file => 'test.key'
    );
    
    isa_ok($handler, 'Plack::Handler::H2', 'Handler object created');
    is($handler->{host}, 'localhost', 'Host attribute set correctly');
    is($handler->{port}, 8443, 'Port attribute set correctly');
    is($handler->{ssl_cert_file}, 'test.crt', 'SSL cert file set correctly');
    is($handler->{ssl_key_file}, 'test.key', 'SSL key file set correctly');
}

{
    my $env = {
        'psgix.h2.stream_id' => 1,
        REQUEST_METHOD => 'GET',
        PATH_INFO => '/test'
    };
    
    my $session = 123456;  # Mock session pointer
    my $responder = Plack::Handler::H2::_responder($env, $session);
    
    isa_ok($responder, 'CODE', 'Responder returns a code reference');
}
