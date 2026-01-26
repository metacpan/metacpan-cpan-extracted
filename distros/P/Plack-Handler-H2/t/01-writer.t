#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use Plack::Handler::H2::Writer;

{
    my $writer = Plack::Handler::H2::Writer->new({
        response => [200, ['Content-Type' => 'text/plain']],
        writer => sub { }
    });
    
    isa_ok($writer, 'Plack::Handler::H2::Writer', 'Writer object created');
    ok(exists $writer->{response}, 'Writer has response attribute');
    ok(exists $writer->{writer}, 'Writer has writer callback');
}

{
    my $write_calls = [];
    my $writer = Plack::Handler::H2::Writer->new({
        response => [200, ['Content-Type' => 'text/plain']],
        writer => sub {
            my ($end_stream, $data) = @_;
            push @$write_calls, { end_stream => $end_stream, data => $data };
        }
    });
    
    $writer->write("Hello, World!");
    
    is(scalar(@$write_calls), 1, 'Write method called writer callback once');
    is($write_calls->[0]->{end_stream}, 0, 'Write method passes end_stream=0');
    is($write_calls->[0]->{data}, "Hello, World!", 'Write method passes correct data');
}

{
    my $close_calls = [];
    my $writer = Plack::Handler::H2::Writer->new({
        response => [200, ['Content-Type' => 'text/plain']],
        writer => sub {
            my ($end_stream, $data) = @_;
            push @$close_calls, { end_stream => $end_stream, data => $data };
        }
    });
    
    $writer->close();
    
    is(scalar(@$close_calls), 1, 'Close method called writer callback once');
    is($close_calls->[0]->{end_stream}, 1, 'Close method passes end_stream=1');
}
