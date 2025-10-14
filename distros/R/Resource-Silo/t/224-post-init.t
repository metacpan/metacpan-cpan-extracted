#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::App224;
    use Resource::Silo -class;
    use Carp;

    resource foo =>
        init        => sub { 42 },
        check       => sub {
            my ($self, $value, $name, $arg) = @_;
            croak "foo must be a number"
                    unless $value =~ /^\d+$/;
        };
}

subtest 'normal usage' => sub {
    my $app = My::App224->new;
    lives_and {
        is $app->foo, 42, "default value as expected";
    }
};

subtest 'good override' => sub {
    my $app = My::App224->new(foo => 137);
    lives_and {
        is $app->foo, 137, "overridden value holds";
    }
};

subtest 'bad override' => sub {
    my $app = My::App224->new(foo => "foo bared");

    # delayed check is bad but we cannot guarantee it anyway.
    # use 'preload' to check all the resources
    throws_ok {
        $app->foo;
    } qr/.*number/;
};

done_testing;
