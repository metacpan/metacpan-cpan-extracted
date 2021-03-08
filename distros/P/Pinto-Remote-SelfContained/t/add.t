#!perl

use v5.10;
use strict;
use warnings;

use Test::Fatal qw(exception);
use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Path::Tiny qw(path);
use lib path(__FILE__)->sibling('lib')->stringify;

use Pinto::Remote::SelfContained::Action::Add;
use T::Chrome;
use T::HTTPTiny;

sub action {
    my ($args, %attrs) = @_;

    local $ENV{PINTO_AUTHOR_ID};
    return Pinto::Remote::SelfContained::Action::Add->new({
        username => 'fred',
        password => undef,
        root => 'http://example.com',
        chrome => T::Chrome->new,
        name => 'add',
        args => $args,
        %attrs,
    });
}

subtest 'add action', sub {
    my $response = "HTTP/1.0 200 OK\r\nContent-type: application/vnd.pinto.v1+text\r\n\r\n## Status: ok\n";
    my $chrome = T::Chrome->new;
    my $httptiny = T::HTTPTiny->new([$response]);

    my $action = action(
        {
            archives => [{
                name => "Foo-Bar-0.01.tar.gz",
                type => 'application/x-tar',
                encoding => 'gzip',
                filename => path(__FILE__)->sibling('corpus/Foo-Bar-0.01.tar.gz'),
            }],
        },
        httptiny => $httptiny,
        chrome => $chrome,
    );

    ok($action->execute->was_successful, 'action executed successfully');
};

had_no_warnings();
done_testing();
