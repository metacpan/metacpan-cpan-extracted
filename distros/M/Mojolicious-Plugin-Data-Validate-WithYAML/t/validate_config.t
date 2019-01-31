#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::Data::Validate::WithYAML';

plugin('Data::Validate::WithYAML' => {
    no_steps => 0,
});

my $t = Test::Mojo->new;

my $app = $t->app;

{
    # no file - should croak
    my $error = '';
    eval {
        FieldInfoTest::test();
    } or $error = $@;

    is $error, '';
}

done_testing();

{
    package
        FieldInfoTest;

    sub test {
        $app->validate(@_);
    }
}
