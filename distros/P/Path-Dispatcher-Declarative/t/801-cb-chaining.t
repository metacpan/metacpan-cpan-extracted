#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

my @result;

do {
    package MyDispatcher;
    use Path::Dispatcher::Declarative -base;

    under show => sub {
        then {
            push @result, "Displaying";
        };
        on inventory => sub {
            push @result, "inventory";
        };
        on score => sub {
            push @result, "score";
        };
    };
};

MyDispatcher->run('show inventory');
is_deeply([splice @result], ['Displaying', 'inventory']);

MyDispatcher->run('show score');
is_deeply([splice @result], ['Displaying', 'score']);

MyDispatcher->run('show');
is_deeply([splice @result], ['Displaying']); # This is kinda weird


