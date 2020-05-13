#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my %tests = (
    user => {
        methods => [qw/username user_password user_id/],
        result  => 1,
    },
    context => {
        methods => [qw/context_id context_name context_description/],
        result  => 1,
    },
    role => {
        methods => [qw/role_id role_name role_description context_id is_valid/],
        result  => 1,
    },
    permission => {
        methods => [qw/permission_id permission_name permission_description resource_id permission_label/],
        result  => 1,
    },
    resource => {
        methods => [qw/resource_id resource_name resource_description resource_label/],
        result  => 1,
    },
);

for my $name ( keys %tests ) {
    state $testnr++;

    my $error;
    my $object;

    eval {
        $object = $db->object( $name );
    } or $error = $@;

    my $is_ok  = $tests{$name}->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $tests{$name}->{result} ) {
        can_ok $object, @{ $tests{$name}->{methods} };
    }
    else {
        like $error, qr/test/;
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
