#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

my @calls;

do {
    package RESTy::Dispatcher;
    use Path::Dispatcher::Declarative -base, -default => {
        token_delimiter => '/',
        case_sensitive_tokens => 0,
    };

    on ['=', 'model', 'Comment'] => sub { push @calls, $3 };
};

ok(RESTy::Dispatcher->isa('Path::Dispatcher::Declarative'), "use Path::Dispatcher::Declarative sets up ISA");

RESTy::Dispatcher->run('= model Comment');
is_deeply([splice @calls], []);

RESTy::Dispatcher->run('/=/model/Comment');
is_deeply([splice @calls], ["Comment"]);

RESTy::Dispatcher->run('/=/model/comment');
is_deeply([splice @calls], ["comment"]);

RESTy::Dispatcher->run('///=///model///COMMENT///');
is_deeply([splice @calls], ["COMMENT"]);

