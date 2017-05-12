#!/usr/bin/env perl

use maint::Maker;

all_from 'lib/Plack/Middleware/Debug/DBIC/QueryLog.pm';
requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::DBIC::QueryLog' => '0.05';
requires 'DBIx::Class::QueryLog'; 
requires 'DBIx::Class::QueryLog::Analyzer';
requires 'SQL::Abstract' => '1.70';
requires 'Moo' => '0.009005';

test_requires 'Test::Fatal';
test_requires 'Test::More' => '0.96';
test_requires 'Plack::Test';
test_requires 'Plack::Builder';
test_requires 'HTTP::Request::Common';
test_requires 'Scalar::Util';
test_requires 'Data::Dump';
test_requires 'Plack::Middleware::DBIC::QueryLog';

tests_recursive;
