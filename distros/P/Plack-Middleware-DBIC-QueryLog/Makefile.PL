#!/usr/bin/env perl

use maint::Maker;

all_from 'lib/Plack/Middleware/DBIC/QueryLog.pm';
requires 'Plack' => '0.9957';
requires 'Moo' => '0.009004';
requires 'DBIx::Class::QueryLog' => '1.3.0';

test_requires 'HTTP::Request::Common';
test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Data::Dump';
test_requires 'Scalar::Util';
test_requires 'Plack::Middleware::Debug';

tests_recursive;
