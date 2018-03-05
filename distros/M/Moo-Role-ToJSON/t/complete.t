#!/usr/bin/env perl

use strict;
use warnings;
use Test2::Bundle::More;
use Test2::Require::Module 'Throwable';
use Test2::Tools::Compare;
use Test2::Tools::Exception 'dies';

# ABSTRACT: a complete/typical example of using Moo::Role::ToJSON

BEGIN {
    package My::Exception;
    use Moo;
    use Types::Standard qw/Str/;

    use overload '""' => sub { $_[0]->message };

    with qw/Throwable Moo::Role::ToJSON/;

    has message => (is => 'ro', isa => Str, required => 1);

    sub _build_serializable_attributes { ['message'] }

    1;

    package My::Exception::Extended;
    use Moo;
    extends 'My::Exception';

    has type => (is => 'ro');

    sub _build_serializable_attributes { ['type', @{shift->next::method}] }

    1;
}

subtest typical_example => \&test_typical_example;

done_testing;

sub test_typical_example {
    eval {
        My::Exception::Extended->throw(message => 'foo', type => 'bar');
    };
    my $error = $@;
    is $error->TO_JSON => {message => 'foo', type => 'bar'};
}
