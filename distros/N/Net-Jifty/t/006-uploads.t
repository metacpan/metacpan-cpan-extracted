#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 39;
use lib 't/lib';
use Net::Jifty::Test;

my $j = Net::Jifty::Test->new();
$j->ua->clear();

$j->get("ping");
my ($name, $args) = $j->ua->next_call();
is($name, 'get', 'ua->get method called');
is($args->[1], 'http://jifty.org/=/ping.yml', 'correct URL');

# all is set, no more fields, simple tests
{
    $j->ua->clear;
    $j->post(['foo'], file => {
        content      => 'stub',
        filename     => 'test.txt',
        content_type => 'text/plain',
    } );

    ($name, $args) = $j->ua->next_call();
    is($name, 'request', 'ua->get method called');

    my $req = $args->[1];
    isa_ok($req, 'HTTP::Request');
    is( $req->content_type, 'multipart/form-data', "multipart form data" );

    my @parts = $req->parts;
    is( scalar @parts, 1, "has one part" );
    is $parts[0]->content_type, 'text/plain', 'correct type of the part';
    is $parts[0]->header('Content-Disposition'),
        'form-data; name="file"; filename="test.txt"',
        'checked disposition';

    is $parts[0]->content, 'stub', 'checked content';
}

# no type - defaults to octet-stream
{
    $j->ua->clear;
    $j->post(['foo'], file => {
        content      => 'stub',
        filename     => 'test.txt',
    } );

    ($name, $args) = $j->ua->next_call();
    is($name, 'request', 'ua->get method called');

    my $req = $args->[1];
    isa_ok($req, 'HTTP::Request');
    is( $req->content_type, 'multipart/form-data', "multipart form data" );

    my @parts = $req->parts;
    is( scalar @parts, 1, "has one part" );
    is $parts[0]->content_type, 'application/octet-stream', 'correct type of the part';
    is $parts[0]->header('Content-Disposition'),
        'form-data; name="file"; filename="test.txt"',
        'checked disposition';

    is $parts[0]->content, 'stub', 'checked content';
}

# mix with another fields
{
    $j->ua->clear;
    $j->post(['foo'],
        file => {
            content      => 'stub',
            filename     => 'test.txt',
        },
        some_arg => 'some_value',
    );

    ($name, $args) = $j->ua->next_call();
    is($name, 'request', 'ua->get method called');

    my $req = $args->[1];
    isa_ok($req, 'HTTP::Request');
    is( $req->content_type, 'multipart/form-data', "multipart form data" );

    my @parts = $req->parts;
    is( scalar @parts, 2, "has two parts" );

    is $parts[0]->content_type, 'application/octet-stream', 'correct type of the part';
    is $parts[0]->header('Content-Disposition'),
        'form-data; name="file"; filename="test.txt"',
        'checked disposition';
    is $parts[0]->content, 'stub', 'checked content';

    is $parts[1]->header('Content-Disposition'),
        'form-data; name="some_arg"',
        'checked disposition';
    is $parts[1]->content, 'some_value', 'checked content';
}

# non ascii file name
{
    $j->ua->clear;
    $j->post(['foo'], file => {
        content      => 'stub',
        filename     => "\x{442}.bin",
    } );

    ($name, $args) = $j->ua->next_call();
    is($name, 'request', 'ua->get method called');

    my $req = $args->[1];
    isa_ok($req, 'HTTP::Request');
    is( $req->content_type, 'multipart/form-data', "multipart form data" );

    my @parts = $req->parts;
    is( scalar @parts, 1, "has one part" );

    is $parts[0]->content_type, 'application/octet-stream', 'correct type of the part';
    is $parts[0]->header('Content-Disposition'),
        'form-data; name="file"; filename="=?UTF-8?Q?=D1=82=2Ebin?="',
        'checked disposition';
    is $parts[0]->content, 'stub', 'checked content';
}

# non ascii input type
{
    $j->ua->clear;
    $j->post(['foo'], "\x{442}" => {
        content      => 'stub',
        filename     => "\x{442}.bin",
    } );

    ($name, $args) = $j->ua->next_call();
    is($name, 'request', 'ua->get method called');

    my $req = $args->[1];
    isa_ok($req, 'HTTP::Request');
    is( $req->content_type, 'multipart/form-data', "multipart form data" );

    my @parts = $req->parts;
    is( scalar @parts, 1, "has one part" );

    is $parts[0]->content_type, 'application/octet-stream', 'correct type of the part';
    is $parts[0]->header('Content-Disposition'),
        'form-data; name="=?UTF-8?Q?=D1=82?="; filename="=?UTF-8?Q?=D1=82=2Ebin?="',
        'checked disposition';
    is $parts[0]->content, 'stub', 'checked content';
}

