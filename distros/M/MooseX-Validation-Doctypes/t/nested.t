#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Moose::Util::TypeConstraints 'find_type_constraint';

use MooseX::Validation::Doctypes;

doctype 'Name' => {
    first => 'Str',
    last  => 'Str',
};

doctype 'Person' => {
    id    => 'Str',
    name  => 'Name',
    title => 'Str',
};

{
    my $person = find_type_constraint('Person');
    isa_ok($person, 'Moose::Meta::TypeConstraint');
    isa_ok($person, 'MooseX::Meta::TypeConstraint::Doctype');

    is_deeply(
        $person->doctype,
        { id => 'Str', name => 'Name', title => 'Str' },
        "got the right doctype"
    );

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => {
                first => 'Bob',
                last  => 'Smith',
            },
            title => 'CIO'
        });
        is($errors, undef, "no errors");
    }

    {
        my $errors = $person->validate({
            id    => '17382-QA',
            name  => {
                first => [],
                last  => 'Smith',
            },
            title => 'CIO',
        });
        isa_ok($errors, 'MooseX::Validation::Doctypes::Errors');
        is_deeply(
            $errors->errors,
            { name => { first => "invalid value [  ] for 'name.first'" } },
            "got the right errors"
        );
        is($errors->extra_data, undef, "no errors");
    }
}

done_testing;
