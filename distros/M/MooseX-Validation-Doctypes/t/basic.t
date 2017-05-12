#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Moose::Util::TypeConstraints 'find_type_constraint';

use MooseX::Validation::Doctypes;

doctype 'Person' => {
    id    => 'Str',
    name  => 'Str',
    title => 'Str',
};

doctype 'Location' => {
    id      => 'Str',
    city    => 'Str',
    state   => 'Str',
    country => 'Str',
    zipcode => 'Int',
};

{
    my $person = find_type_constraint('Person');
    isa_ok($person, 'Moose::Meta::TypeConstraint');
    isa_ok($person, 'MooseX::Meta::TypeConstraint::Doctype');

    is_deeply(
        $person->doctype,
        { id => 'Str', name => 'Str', title => 'Str' },
        "got the right doctype"
    );

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => 'Bob',
            title => 'CIO'
        });
        is($errors, undef, "no errors");
    }

    {
        my $errors = $person->validate({
            id            => '17382-QA',
            name          => 'Bob',
            title         => 'CIO',
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
            id   => '17382-QA',
            name => 'Bob',
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

{
    my $location = find_type_constraint('Location');
    isa_ok($location, 'Moose::Meta::TypeConstraint');
    isa_ok($location, 'MooseX::Meta::TypeConstraint::Doctype');

    {
        my $errors = $location->validate({
            id      => 'My House',
            city    => 'Anytown',
            state   => 'IL',
            country => 'USA',
            zipcode => 'ABCDEF'
        });
        isa_ok($errors, 'MooseX::Validation::Doctypes::Errors');
        is($errors->extra_data, undef, "no extra data");
        is_deeply(
            $errors->errors,
            { zipcode => "invalid value \"ABCDEF\" for 'zipcode'" },
            "got the right errors"
        );
    }
}

done_testing;
