#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use Test::More;
	unless( ( $ENV{AUTHOR_TESTING} && $ENV{AUTHOR_TESTING} > 1 ) || $ENV{RELEASE_TESTING} )
	{
        plan(skip_all => 'These tests are for author or release candidate testing');
    }
};

eval { require Test::Prereq; Test::Prereq->import() }; 
plan( skip_all => 'Test::Prereq not installed; skipping' ) if $@;
prereq_ok( undef, [qw(
    warnings::register
    Changes::Version
    HTTP::Promise::Headers HTTP::Promise::Parser HTTP::Promise::Request HTTP::Promise::Response
    HTTP::Promise::Status Module::Generic::Exception Module::Generic::File
    Module::Signature
    Test::Kwalitee Test::Prereq
)] );
