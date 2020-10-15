use strict;
use warnings;

use English;
use File::Object;
use PYX::SGML::Tags;
use Test::More 'tests' => 4;
use Test::NoWarnings;

SKIP: {
	eval {
		require Tags::Output::LibXML;
	};
	if ($EVAL_ERROR) {
		skip "Module 'Tags::Output::LibXML' isn't present.", 3;
	}

	# Directories.
	my $data_dir = File::Object->new->up->dir('data');

	# Test.
	my $tags = Tags::Output::LibXML->new;
	my $obj = PYX::SGML::Tags->new(
		'tags' => $tags,
	);
	eval {
		$obj->parse_file($data_dir->file('char1.pyx')->s);
	};
	like($EVAL_ERROR, qr{^Can't call method "addChild" on an undefined value},
		'Not possible add data without root element.');
	$tags->reset;

	# Test.
	eval {
		$obj->parse_file($data_dir->file('char2.pyx')->s);
	};
	like($EVAL_ERROR, qr{^Can't call method "addChild" on an undefined value},
		'Not possible add data without root element.');
	$tags->reset;

	# Test.
	eval {
		$obj->parse_file($data_dir->file('char3.pyx')->s);
	};
	like($EVAL_ERROR, qr{^Can't call method "addChild" on an undefined value},
		'Not possible add data without root element.');
	$tags->reset;
};
