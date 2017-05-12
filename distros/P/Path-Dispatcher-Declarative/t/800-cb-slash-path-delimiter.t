#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

my @result;

do {
    package MyDispatcher;
    use Path::Dispatcher::Declarative -base, -default => {
        token_delimiter => '/',
    };

    under show => sub {
        on inventory => sub {
            push @result, "inventory";
        };
        on score => sub {
            push @result, "score";
        };
    };
};

MyDispatcher->run('show/inventory');
is_deeply([splice @result], ['inventory']);

MyDispatcher->run('show/score');
is_deeply([splice @result], ['score']);

MyDispatcher->run('show inventory');
is_deeply([splice @result], []);

