#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

my @calls;
do {
    package Web::Dispatcher;
    use base 'Path::Dispatcher::Declarative';

    use constant token_delimiter => '/';


    package My::Other::Dispatcher;
    # we can't use a package in the same file :/
    BEGIN { Web::Dispatcher->import('-base') };

    on ['foo', 'bar'] => sub {
        push @calls, '/foo/bar';
    };
};

My::Other::Dispatcher->run('/foo/bar');
is_deeply([splice @calls], ['/foo/bar']);

