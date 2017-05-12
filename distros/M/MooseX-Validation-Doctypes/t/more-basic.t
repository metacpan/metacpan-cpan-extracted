#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Moose::Util::TypeConstraints 'find_type_constraint';

use MooseX::Validation::Doctypes;

doctype 'Location' => {
    id      => 'Str',
    city    => 'Str',
    state   => 'Str',
    country => 'Str',
    zipcode => 'Int',
};

doctype 'Person' => {
    id    => 'Str',
    name  => {
        first_name => 'Str',
        last_name  => 'Str',
    },
    title   => 'Str',
    friends => 'ArrayRef[Person]',
    address => 'Maybe[Location]'
};


{
    my $person = find_type_constraint('Person');
    isa_ok($person, 'Moose::Meta::TypeConstraint');
    isa_ok($person, 'MooseX::Meta::TypeConstraint::Doctype');

    is_deeply(
        $person->doctype,
        {
            id    => 'Str',
            name  => {
                first_name => 'Str',
                last_name  => 'Str',
            },
            title   => 'Str',
            friends => 'ArrayRef[Person]',
            address => 'Maybe[Location]'
        },
        "got the right doctype"
    );

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => {
                first_name => 'Bob',
                last_name  => 'Smith',
            },
            title => 'CIO',
            friends => [],
            address => {
                id      => 'My House',
                city    => 'Anytown',
                state   => 'IL',
                country => 'USA',
                zipcode => '12345'
            }
        });

        is($errors, undef, "no errors");
    }

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => {
                first_name => 'Bob',
                last_name  => 'Smith',
            },
            title => 'CIO',
            friends => [],
            favorite_food => 'ice cream',
        });
        isa_ok($errors, 'MooseX::Validation::Doctypes::Errors');
        is_deeply(
            $errors->extra_data,
            { favorite_food => 'ice cream' },
            "got the right extra data"
        );
        is($errors->errors, undef, "no errors");
    }

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => {
                first_name => 'Bob',
                last_name  => 'Smith',
            },
            friends => [],
            address => {
                id      => 'My House',
                city    => 'Anytown',
                state   => 'IL',
                country => 'USA',
                zipcode => '12345'
            }
        });
        isa_ok($errors, 'MooseX::Validation::Doctypes::Errors');
        is($errors->extra_data, undef, "no extra data");
        is_deeply(
            $errors->errors,
            { title => "invalid value undef for 'title'" },
            "got the right errors"
        );
    }
}

done_testing;
