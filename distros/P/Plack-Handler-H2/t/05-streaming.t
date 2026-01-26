#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 11;
use Plack::Handler::H2::Writer;

{
    my $calls = [];
    my $writer = Plack::Handler::H2::Writer->new({
        response => [200, ['Content-Type' => 'text/plain']],
        writer => sub {
            my ($end_stream, $data) = @_;
            push @$calls, { end_stream => $end_stream, data => $data };
        }
    });
    
    $writer->write("First chunk");
    $writer->write("Second chunk");
    $writer->write("Third chunk");
    $writer->close();
    
    is(scalar(@$calls), 4, 'Four callbacks made for three writes and one close');
    
    is($calls->[0]->{end_stream}, 0, 'First write has end_stream=0');
    is($calls->[0]->{data}, "First chunk", 'First write has correct data');
    
    is($calls->[1]->{end_stream}, 0, 'Second write has end_stream=0');
    is($calls->[1]->{data}, "Second chunk", 'Second write has correct data');
    
    is($calls->[2]->{end_stream}, 0, 'Third write has end_stream=0');
    is($calls->[2]->{data}, "Third chunk", 'Third write has correct data');
    
    is($calls->[3]->{end_stream}, 1, 'Close has end_stream=1');
    is($calls->[3]->{data}, undef, 'Close has no data');
}

{
    my $calls = [];
    my $writer = Plack::Handler::H2::Writer->new({
        response => [200, ['Content-Type' => 'text/plain']],
        writer => sub {
            my ($end_stream, $data) = @_;
            push @$calls, { end_stream => $end_stream, data => $data };
        }
    });
    
    $writer->close();
    
    is(scalar(@$calls), 1, 'One callback made for close without write');
    is($calls->[0]->{end_stream}, 1, 'Close without prior writes has end_stream=1');
}
