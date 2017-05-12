use strict;
use warnings;

use lib 't/lib';

use CatalystLike::Controller;
use CatalystLike::Controller::Moose;
use CatalystLike::Controller::Moose::MethodModifiers;

use Test::More tests => 13;
use Test::Fatal;

my @methods;
is exception {
    @methods = CatalystLike::Controller::Moose::MethodModifiers->meta->get_nearest_methods_with_attributes;
}, undef, 'Can get nearest methods';

is @methods, 3;

my $method = (grep { $_->name eq 'get_attribute' } @methods)[0];
ok $method;
is $method->body, \&CatalystLike::Controller::Moose::MethodModifiers::get_attribute;
is $CatalystLike::Controller::Moose::GET_ATTRIBUTE_CALLED, 0;
is $CatalystLike::Controller::Moose::MethodModifiers::GET_ATTRIBUTE_CALLED, 0;
is $CatalystLike::Controller::Moose::GET_FOO_CALLED, 0;
is $CatalystLike::Controller::Moose::BEFORE_GET_FOO_CALLED, 0;
$method->body->();
(grep { $_->name eq 'get_foo' } @methods)[0]->body->();
is $CatalystLike::Controller::Moose::GET_ATTRIBUTE_CALLED, 1;
is $CatalystLike::Controller::Moose::MethodModifiers::GET_ATTRIBUTE_CALLED, 1;
is $CatalystLike::Controller::Moose::GET_FOO_CALLED, 1;
is $CatalystLike::Controller::Moose::BEFORE_GET_FOO_CALLED, 1;

my $other = (grep { $_->name eq 'other' } @methods)[0];
ok $other;

