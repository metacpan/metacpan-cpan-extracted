#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
);

{
    my $error;
    eval {
        $context->load;
    } or $error = 1;

    ok $error;
}

{
    my $error;
    eval {
        $context->load( $db );
    } or $error = 1;

    ok $error;
}

{
    my $error;
    eval {
        $context->load(undef);
    } or $error = 1;

    is $context->error, 'Need id';
}

ok !$context->load(1);

my $new_context = $context->add(
    context_name => 'test',
);

ok $context->load( $new_context->context_id );
isa_ok $new_context, 'Mojolicious::Plugin::ContextAuth::DB::Context';
is $new_context->context_name, 'test';

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
