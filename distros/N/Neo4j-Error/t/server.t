#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Warnings;


use Neo4j::Error;

plan tests => 8 + 4 + 1;

my $e;


subtest 'new code' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => { code => $code }), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->category(), 'General', 'category';
	is $e->title(), 'UnknownError', 'title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new non-Neo4j code' => sub {
	plan tests => 8;
	my $code = 'Neo.Fantasy.Whatever';
	ok $e = Neo4j::Error->new(Server => { code => $code }), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	is $e->classification(), '', 'no classification';
	is $e->category(), '', 'no category';
	is $e->title(), '', 'no title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new code parts' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => {
		classification => 'DatabaseError',
		category => 'General',
		title => 'UnknownError',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code from parts';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->category(), 'General', 'category';
	is $e->title(), 'UnknownError', 'title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new code, classification called first' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => { code => $code }), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->code(), $code, 'code from parts';
	is $e->category(), 'General', 'category';
	is $e->title(), 'UnknownError', 'title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new code, category called first' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => { code => $code }), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->category(), 'General', 'category';
	is $e->code(), $code, 'code from parts';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->title(), 'UnknownError', 'title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new code, title called first' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => { code => $code }), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->title(), 'UnknownError', 'title';
	is $e->code(), $code, 'code from parts';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->category(), 'General', 'category';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\b\Q$code\E\b/i, 'as_string';
};


subtest 'new code parts incomplete' => sub {
	plan tests => 8;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => {
		classification => 'DatabaseError',
		title => 'UnknownError',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->category(), '', 'no category';
	is $e->code(), '', 'no code from parts';
	is $e->classification(), 'DatabaseError', 'classification';
	is $e->title(), 'UnknownError', 'title';
	is $e->message(), '', 'no message';
	like $e->as_string(), qr/\bmain::__ANON__\b/i, 'as_string trace fallback';
};


subtest 'new strict Jolt' => sub {
	plan tests => 4;
	my $code = 'Neo.DatabaseError.General.UnknownError';
	ok $e = Neo4j::Error->new(Server => {
		code    => {U => $code},
		message => {U => 'msg'},
	}), 'new';
	is $e->code(), $code, 'code';
	is $e->message(), 'msg', 'message';
	like $e->as_string(), qr/\b\Q$code\E\b.*\bmsg\b/i, 'as_string';
};


subtest 'new ClientError' => sub {
	plan tests => 6;
	my $code = 'Neo.ClientError.LegacyIndex.LegacyIndexNotFound';
	ok $e = Neo4j::Error->new(Server => {
		code => $code,
		message => 'The request referred to an explicit index that does not exist.',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	like $e->message(), qr/ explicit index /i, 'message';
	like $e->as_string(), qr/\b\Q$code\E\b.* explicit index /i, 'as_string';
	ok ! $e->is_retryable(), 'no is_retryable';
};


subtest 'new ClientNotification' => sub {
	plan tests => 6;
	my $code = 'Neo.ClientNotification.Statement.NoApplicableIndex';
	ok $e = Neo4j::Error->new(Server => {
		code => $code,
		message => 'Adding a schema index may speed up this query.',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	like $e->message(), qr/ schema index /i, 'message';
	like $e->as_string(), qr/\b\Q$code\E\b.* schema index /i, 'as_string';
	ok ! $e->is_retryable(), 'no is_retryable';
};


subtest 'new TransientError' => sub {
	plan tests => 6;
	my $code = 'Neo.TransientError.Security.AuthProviderFailed';
	ok $e = Neo4j::Error->new(Server => {
		code => $code,
		message => 'An auth provider request failed.',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	like $e->message(), qr/ auth provider request /i, 'message';
	like $e->as_string(), qr/\b\Q$code\E\b.* auth provider request /i, 'as_string';
	ok $e->is_retryable(), 'yes is_retryable';
};


subtest 'new DatabaseError' => sub {
	plan tests => 6;
	my $code = 'Neo.DatabaseError.Database.Unknown';
	ok $e = Neo4j::Error->new(Server => {
		code => $code,
		message => 'Unknown database management error.',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->code(), $code, 'code';
	like $e->message(), qr/ database management /i, 'message';
	like $e->as_string(), qr/\b\Q$code\E\b.* database management /i, 'as_string';
	ok ! $e->is_retryable(), 'no is_retryable';
};


done_testing;
