#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
	NAME             => 'Plack::Session::Store::Echo',
	AUTHOR           => 'Denis Ibaev <dionys@cpan.org>',
	VERSION_FROM     => 'lib/Plack/Session/Store/Echo.pm',
	ABSTRACT_FROM    => 'lib/Plack/Session/Store/Echo.pm',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.8.0',
	BUILD_REQUIRES   => {
		'Test::More'                 => 0,
	},
	PREREQ_PM        => {
		'parent'                     => 0,
		'Plack::Middleware::Session' => 0,
	},
	META_MERGE       => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			repository  => 'http://github.com/dionys/plack-session-store-echo',
			bugtracker  => 'http://github.com/dionys/plack-session-store-echo/issues',
		},
		no_index  => {directory => ['t']},
	},
	dist             => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	clean            => {FILES => 'Plack-Session-Store-Echo-*'},
	test             => {TESTS => 't/*.t'},
);
