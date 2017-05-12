use strict;
use warnings;
use v5.10;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub { [200,[],[shift->{QUERY_STRING}]] };

my $stack = builder { 
    enable 'Negotiate',
        formats => {
            txt  => { 
                type => 'text/plain',
                app  => $app,
            },
        },
        parameter => 'format';
    $app;
};

my %tests = (
    '/foo.txt' => '',
    '/foo?xformat=txt' => 'xformat=txt',
    '/?format=txt&foo=bar' => 'foo=bar',
    '/?foo=bar&format=txt' => 'foo=bar',
    '/?foo=bar&format=txt&doz=baz' => 'foo=bar&doz=baz',
);

test_psgi $stack => sub {
    my $cb = shift;
    while (my ($url, $content) = each %tests) {
        my $res = $cb->(GET $url);
        is $res->content, $content;
    }
};

done_testing;
