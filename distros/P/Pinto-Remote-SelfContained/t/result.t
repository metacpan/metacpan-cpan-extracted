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
use Pinto::Remote::SelfContained;
use URI;

subtest 'response dialog' => sub {
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

    my $remote = Pinto::Remote::SelfContained->new(
        root => 'http://example.com/',
        chrome => $chrome,
        httptiny => $httptiny,
    );

    my $result = $remote->run('List');

    isa_ok($result, 'Pinto::Remote::SelfContained::Result', 'result object')
        and ok($result->was_successful, 'result was successful');
    is(${ $chrome->stdout_buf }, "DATA-GOES-HERE\n", 'stdout');
    is(${ $chrome->stderr_buf }, "DIAG-MSG-HERE\n", 'stderr');
};

had_no_warnings();
done_testing();
