#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 12;
use Plack::Handler::H2;

{
    my $env = {
        'psgix.h2.stream_id' => 1,
        REQUEST_METHOD => 'GET',
        PATH_INFO => '/test'
    };
    
    my $session = 123456;
    my $responder = Plack::Handler::H2::_responder($env, $session);
    
    my $response = [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello World']
    ];
    
    my $result = $responder->($response);
    is_deeply($result, $response, 'Responder returns array response unchanged for complete response');
}

{
    my $env = {
        'psgix.h2.stream_id' => 2,
        REQUEST_METHOD => 'GET',
        PATH_INFO => '/stream'
    };
    
    my $session = 789012;
    
    no warnings 'redefine';
    local *Plack::Handler::H2::ph2_stream_write_headers_wrapper = sub {
        my ($env, $session, $response) = @_;
        return 1;
    };
    
    my $writer_calls = [];
    local *Plack::Handler::H2::ph2_stream_write_data_wrapper = sub {
        my ($env, $session, $end_stream, $data) = @_;
        push @$writer_calls, { end_stream => $end_stream, data => $data };
    };
    use warnings 'redefine';
    
    my $responder = Plack::Handler::H2::_responder($env, $session);
    
    my $response = [
        200,
        ['Content-Type' => 'text/plain']
    ];
    
    my $result = $responder->($response);
    isa_ok($result, 'Plack::Handler::H2::Writer', 'Responder returns Writer for streaming response');
    
    $result->write('chunk1');
    is(scalar(@$writer_calls), 1, 'Writer callback called once');
    is($writer_calls->[0]->{end_stream}, 0, 'write() sets end_stream=0');
    is($writer_calls->[0]->{data}, 'chunk1', 'write() passes correct data');
    
    $result->write('chunk2');
    is(scalar(@$writer_calls), 2, 'Writer callback called twice');
    is($writer_calls->[1]->{data}, 'chunk2', 'Second write() passes correct data');
    
    $result->close();
    is(scalar(@$writer_calls), 3, 'Close calls writer callback');
    is($writer_calls->[2]->{end_stream}, 1, 'close() sets end_stream=1');
}

{
    my $env = {
        'psgix.h2.stream_id' => 3,
        REQUEST_METHOD => 'GET',
        PATH_INFO => '/invalid'
    };
    
    my $session = 345678;
    
    # Mock the XS functions
    no warnings 'redefine';
    local *Plack::Handler::H2::ph2_stream_write_headers_wrapper = sub { 1 };
    local *Plack::Handler::H2::ph2_stream_write_data_wrapper = sub { };
    use warnings 'redefine';
    
    my $responder = Plack::Handler::H2::_responder($env, $session);
    
    # Test with invalid response (too few elements)
    my $warnings = [];
    local $SIG{__WARN__} = sub { push @$warnings, shift };
    
    my $result = $responder->([500]);
    
    is_deeply($result, [500, ['Content-Type' => 'text/plain'], ['Internal Server Error: invalid response from application']], 
              'Responder returns error response for invalid input');
    like($warnings->[0], qr/Invalid PSGI response/, 'Warning issued for invalid response');
}

{
    my $env = {
        'psgix.h2.stream_id' => 4,
        REQUEST_METHOD => 'GET',
        PATH_INFO => '/invalid2'
    };
    
    my $session = 901234;
    
    no warnings 'redefine';
    local *Plack::Handler::H2::ph2_stream_write_headers_wrapper = sub { 1 };
    local *Plack::Handler::H2::ph2_stream_write_data_wrapper = sub { };
    use warnings 'redefine';
    
    my $responder = Plack::Handler::H2::_responder($env, $session);
    
    my $warnings = [];
    local $SIG{__WARN__} = sub { push @$warnings, shift };
    
    my $result = $responder->("not an array");
    
    is_deeply($result, [500, ['Content-Type' => 'text/plain'], ['Internal Server Error: invalid response from application']], 
              'Responder returns error response for non-array input');
}
