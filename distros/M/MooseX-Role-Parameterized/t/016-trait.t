#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 0.88;

do {
    package MyTrait::Label;
    use MooseX::Role::Parameterized;

    parameter default => (
        is  => 'rw',
        isa => 'Str',
    );

    role {
        my $p = shift;

        has label => (
            is      => 'rw',
            isa     => 'Str',
            default => $p->default,
        );
    };
};

do {
    package MyClass::LabeledURL;
    use Moose;

    has url => (
        is => 'ro',
        traits => [
            'MyTrait::Label' => { default => 'yay' },
        ],
    );
};

do {
    package MyClass::LabeledURL::Redux;
    use Moose;

    has 'url' => (
        is => 'ro',
        traits => [
            'MyTrait::Label' => { default => 'yay' },
        ],
        label => 'overridden',
    );
};

is(MyClass::LabeledURL->meta->get_attribute('url')->label, 'yay');
is(MyClass::LabeledURL::Redux->meta->get_attribute('url')->label, 'overridden');

done_testing;
