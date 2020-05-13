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

my $new_context = $context->add(
    context_name => 'test',
);

ok $context->load( $new_context->context_id );
isa_ok $new_context, 'Mojolicious::Plugin::ContextAuth::DB::Context';
is $new_context->context_name, 'test';

{
    my $updated_context = $new_context->update(
        context_name => 'ernie',
    );

    ok $updated_context;
    isa_ok $updated_context, 'Mojolicious::Plugin::ContextAuth::DB::Context';
    is $updated_context->context_name, 'ernie';
    isnt $updated_context->context_name, $new_context->context_name;
}

{
    my $updated_context = $context->update(
        $new_context->context_id,
        context_name => 'sheldon',
    );

    ok $updated_context;
    isa_ok $updated_context, 'Mojolicious::Plugin::ContextAuth::DB::Context';
    is $updated_context->context_name, 'sheldon';
    isnt $updated_context->context_name, $new_context->context_name;
}

{
    my $updated = $new_context->update(
        context_description => 'a description',
    );

    ok $updated;
    is $new_context->error, '';
    is $updated->context_description, 'a description';
}

{
    ok !$new_context->update(
        context_name => ''
    );

    is $new_context->error, 'Invalid parameter'
}

{
    ok !$new_context->update(
        context_name => 'te'
    );

    is $new_context->error, 'Invalid parameter'
}

{
    ok !$new_context->update(
        context_name => 'te' x 500
    );

    is $new_context->error, 'Invalid parameter'
}

{
    ok !$new_context->update(
        context_name => 'test_context',
        arg3         => 1323,
    );

    is $new_context->error, 'Invalid parameter'
}

{
    ok !$context->update( 123, context_name => 'non-existent-context' );
    is $context->error, 'No context updated';
}

{
    ok $context->update( $new_context->context_id, context_name => 'non-existent-context' );
    is $context->error, '';
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
