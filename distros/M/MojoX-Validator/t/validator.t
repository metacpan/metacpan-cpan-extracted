#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use MojoX::Validator;

my $validator = MojoX::Validator->new;
$validator->field('firstname')->required(1);
$validator->field('website')->length(3, 20);

ok($validator->validate({firstname => 'bar', website => 'http://fooo.com'}));
is_deeply($validator->values,
    {firstname => 'bar', website => 'http://fooo.com'});
