#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires 'JSON';

use Moose::Util::TypeConstraints 'find_type_constraint';

use MooseX::Validation::Doctypes;

doctype 'Person' => {
    id    => 'Str',
    name  => 'Str',
    title => 'Str',
};

my $JSON = JSON->new->utf8->convert_blessed;

{
    my $person = find_type_constraint('Person');
    my $errors = $person->validate({ foo => "bar" });

    is_deeply(
        $JSON->decode($JSON->encode($errors)),
        {
            errors => {
                id    => "invalid value undef for 'id'",
                name  => "invalid value undef for 'name'",
                title => "invalid value undef for 'title'",
            },
            extra_data => {
                foo => "bar",
            },
        },
        "error objects can be encoded as json"
    );
}

done_testing;
