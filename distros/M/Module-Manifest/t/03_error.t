#!/usr/bin/perl

#  Tests that Module::Manifest throws appropriate exceptions and warnings

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 21;
use Test::Warn;
use Test::Exception;
use Module::Manifest ();

# Fail if open called without a filename
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->open('skip');
	},
	qr/must pass a filename/,
	'Enforce filename/path to $manifest->open call'
);
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->open(skip => '');
	},
	qr/must pass a filename/,
	'Enforce filename/path to $manifest->open call'
);

# Fail unless open called with a readable file
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->open(skip => 't');
	},
	qr/readable file path/,
	'Enforce readable file for $manifest->open call'
);

# Fail when parse called without an array reference
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->parse(manifest => 'file');
	},
	qr/specified as an array reference/,
	'Enforce ARRAY ref with parse'
);

# Fail if skipped called without a filename
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		my $skip = $manifest->skipped;
	},
	qr/must pass a filename/,
	'Enforce filename/path to $manifest->skipped call'
);
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		my $skip = $manifest->skipped('');
	},
	qr/must pass a filename/,
	'Enforce filename/path to $manifest->skipped call'
);

# Fail when parse called with invalid type
throws_ok(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->parse(invalid => [ 'file' ]);
	},
	qr/Available types are/,
	'Enforce type parameter to parse'
);

# Fail when calls are not object methods
throws_ok(
	sub {
		Module::Manifest->open;
	},
	qr/as an object/,
	'Static Module::Manifest->open call'
);

throws_ok(
	sub {
		Module::Manifest->parse;
	},
	qr/as an object/,
	'Static Module::Manifest->parse call'
);

throws_ok(
	sub {
		my $dir = Module::Manifest->dir;
	},
	qr/as an object/,
	'Static Module::Manifest->dir call'
);

throws_ok(
	sub {
		my $skip = Module::Manifest->skipfile;
	},
	qr/as an object/,
	'Static Module::Manifest->skipfile call'
);

throws_ok(
	sub {
		my $skip = Module::Manifest->skipped('testmask');
	},
	qr/as an object/,
	'Static Module::Manifest->skipped call'
);

throws_ok(
	sub {
		my $file = Module::Manifest->file;
	},
	qr/as an object/,
	'Static Module::Manifest->file call'
);

throws_ok(
	sub {
		my $file = Module::Manifest->files;
	},
	qr/as an object/,
	'Static Module::Manifest->files call'
);

# Test that duplicate items elicit a warning
warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->parse(manifest => [
			'.svn',
			'.svn/config',
			'Makefile.PL',
			'Makefile.PL',
		]);
	},
	qr/Duplicate file/,
	'Duplicate insertions cause warning'
);

# Warning emitted when accessors used in void context
warning_like(
	sub {
		Module::Manifest->new;
	},
	qr/discarded/,
	'Module::Manifest->new called in void context'
);

warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->dir;
	},
	qr/discarded/,
	'$manifest->dir called in void context'
);

warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->skipfile;
	},
	qr/discarded/,
	'$manifest->skipfile called in void context'
);

warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->skipped('testmask');
	},
	qr/discarded/,
	'$manifest->skipped called in void context'
);

warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->file;
	},
	qr/discarded/,
	'$manifest->file called in void context'
);

warning_like(
	sub {
		my $manifest = Module::Manifest->new;
		$manifest->files;
	},
	qr/discarded/,
	'$manifest->files called in void context'
);
