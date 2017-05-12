#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

my @calls;

do {
    package Under::Where;
    use Path::Dispatcher::Declarative -base;

    under 'ticket' => sub {
        on 'create' => sub { push @calls, "ticket create" };
        on 'update' => sub { push @calls, "ticket update" };
    };

    under 'blog' => sub {
        under 'post' => sub {
            on 'create' => sub { push @calls, "create blog post" };
            on 'delete' => sub { push @calls, "delete blog post" };
        };
        under 'comment' => sub {
            on 'create' => sub { push @calls, "create blog comment" };
            on 'delete' => sub { push @calls, "delete blog comment" };
        };
    };
};

Under::Where->run('ticket create');
is_deeply([splice @calls], ['ticket create']);

Under::Where->run('ticket update');
is_deeply([splice @calls], ['ticket update']);

Under::Where->run('ticket foo');
is_deeply([splice @calls], []);

Under::Where->run('blog');
is_deeply([splice @calls], []);

Under::Where->run('blog post');
is_deeply([splice @calls], []);

Under::Where->run('blog post create');
is_deeply([splice @calls], ['create blog post']);

Under::Where->run('blog comment');
is_deeply([splice @calls], []);

Under::Where->run('blog comment create');
is_deeply([splice @calls], ['create blog comment']);

