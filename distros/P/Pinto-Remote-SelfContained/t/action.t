#!perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Path::Tiny qw(path);
use lib path(__FILE__)->sibling('lib')->stringify;

use T::Chrome;
use T::HTTPTiny;
use Pinto::Remote::SelfContained::Action;
use URI;

subtest 'response parts' => sub {
    my $body = join '', map "$_\n", (
        'DATA-GOES-HERE',
        '## DIAG-MSG-HERE',
        '## Status: ok',
    );
    my $chrome = T::Chrome->new;
    my $httptiny = T::HTTPTiny->new([join('', (
        "HTTP/1.1 200 OK\r\n",
        "Content-type: application/vnd.pinto.v1+text\r\n",
        "\r\n",
        $body,
    ))]);

    my $action = Pinto::Remote::SelfContained::Action->new(
        username => 'fred',
        password => undef,
        root => 'http://example.com',
        chrome => $chrome,
        httptiny => $httptiny,
        name => 'list',
    );

    my $response = $action->_send_request;
    is_deeply(
        $response,
        {
            success => 1,
            url => URI->new('http://example.com/action/list'),
            protocol => 'HTTP/1.1',
            status => 200,
            reason => 'OK',
            headers => { 'Content-type' => 'application/vnd.pinto.v1+text' },
            content => $body,
        },
        'parts of response are correct',
    );
};

subtest 'streaming' => sub {
    my @body = (
        'DATA-GOES-HERE',
        '## DIAG-MSG-HERE',
        'ANOTHER-DATA-LINE',
        '## Status: ok',
    );
    my $body = join '', map "$_\n", @body;
    my $chrome = T::Chrome->new;
    my $httptiny = T::HTTPTiny->new([join('', (
        "HTTP/1.1 200 OK\r\n",
        "Content-type: application/vnd.pinto.v1+text\r\n",
        "\r\n",
        $body,
    ))]);

    my $action = Pinto::Remote::SelfContained::Action->new(
        username => 'fred',
        password => undef,
        root => 'http://example.com',
        chrome => $chrome,
        httptiny => $httptiny,
        name => 'list',
    );

    my @lines;
    my $streaming_callback = sub { push @lines, [@_] };
    my $response = $action->_send_request(undef, $streaming_callback);
    is_deeply(\@lines, [ map [$_], @body[0, 2] ], 'streamed response');
};

had_no_warnings();
done_testing();
