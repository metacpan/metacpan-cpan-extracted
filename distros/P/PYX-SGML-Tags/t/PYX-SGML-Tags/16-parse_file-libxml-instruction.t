use strict;
use warnings;

use English;
use File::Object;
use PYX::SGML::Tags;
use Test::More 'tests' => 3;
use Test::NoWarnings;

SKIP: {
	eval {
		require Tags::Output::LibXML;
	};
	if ($EVAL_ERROR) {
		skip "Module 'Tags::Output::LibXML' isn't present.", 2;
	}

	# Directories.
	my $data_dir = File::Object->new->up->dir('data');

	# Test.
	my $tags = Tags::Output::LibXML->new;
	my $obj = PYX::SGML::Tags->new(
		'tags' => $tags,
	);
	$obj->parse_file($data_dir->file('instruction1.pyx')->s);
	my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<?target code?>
END
	is($tags->flush, $right_ret, 'Simple instruction.');
	$tags->reset;

	# Test.
	$obj->parse_file($data_dir->file('instruction2.pyx')->s);
	$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<?target data\ndata?>
END
	is($tags->flush, $right_ret,
		'Instruction with newline in data section.');
	$tags->reset;
};
