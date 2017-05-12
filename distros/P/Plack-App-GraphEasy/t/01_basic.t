use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::GraphEasy;

my $app = Plack::App::GraphEasy->new->to_app;

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'text/html', 'content_type';
        is $res->content_type_charset, 'UTF-8';
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', { text => '' });

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'text/plain', 'content_type';
        is $res->content, 'no text';
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', { text => '[foo]' });

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'text/plain', 'content_type';
        is $res->content, <<'_GRAPH_', 'body';
+-----+
| foo |
+-----+
_GRAPH_
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', { text => '[A]->[B][C]->[D]' });

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'text/plain', 'content_type';
        is $res->content, <<'_GRAPH_', 'body';
+---+     +---+
| A | --> | B |
+---+     +---+
+---+     +---+
| C | --> | D |
+---+     +---+
_GRAPH_
    };
}

{
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', { text => <<'_INPUT_' });
[ Long Node Label\l left\r right\c center ]
 -- A\r long\n edge label --> [ B ]
_INPUT_
        is $res->code, 200, 'response status 200';
        is $res->content_type, 'text/plain', 'content_type';
        is $res->content, <<'_GRAPH_', 'body';
+-----------------+               +---+
| Long Node Label |  A            |   |
| left            |        long   | B |
|           right |  edge label   |   |
|     center      | ------------> |   |
+-----------------+               +---+
_GRAPH_
    };
}

done_testing;
