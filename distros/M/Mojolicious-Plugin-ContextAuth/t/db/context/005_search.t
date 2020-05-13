#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

use feature 'postderef';
no warnings 'experimental::postderef';

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
);

my $new_context = $context->add(
    context_name => 'test',
);

my $new_context_2 = $context->add(
    context_name => 'hello',
    context_description => 'A simple project',
);

my @searches = (
    {
        data    => {},
        success => 1,
        check   => [ $new_context, $new_context_2 ],
    },
    {
        data    => {
            context_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_context_2 ],
    },
    {
        data    => {
            context_name => 'test'
        },
        success => 1,
        check   => [ $new_context ],
    },
    {
        data    => {
            context_name => { LIKE => 'te%' },
        },
        success => 1,
        check   => [ $new_context ],
    },
    {
        data    => {
            context_name => { LIKE => 'he%' },
            context_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_context_2 ],
    },
    {
        data    => {
            context_name => { LIKE => 'te%' },
            context_description => 'A simple project',
        },
        success => 1,
        check   => [],
    },
    {
        data    => {
            arg3 => 'test',
        },
        success => 0,
        error   => 'Cannot search for contexts',
    },
);

for my $search ( @searches ) {
    state $cnt++;

    my @contexts = $context->search( $search->{data}->%* );

    if ( $search->{success} ) {
        check( \@contexts, $search->{check}, $cnt );
        is $context->error, '';
    }
    else {
        ok !@contexts;
        is $context->error, $search->{error};
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub check {
    my ($got, $expected, $cnt) = @_;

    is_deeply {
        map{ $_ => 1 }$got->@*,
    }, {
        map{ $_->context_id => 1 }$expected->@*,
    }, "Deeply $cnt";
}