#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::Data::Validate::WithYAML';

## Webapp START

my $dir = app->home->to_string;

plugin('Data::Validate::WithYAML');

## Webapp END

my $t = Test::Mojo->new;

my $app = $t->app;

{
    # no file - should croak
    my $error = '';
    eval {
        FieldInfoTest::fi();
    } or $error = $@;

    like $error, qr/fi\.yml does not exist/;
}

done_testing();

{
    package
        FieldInfoTest;

    sub fi {
        $app->fieldinfo(@_);
    }
}
