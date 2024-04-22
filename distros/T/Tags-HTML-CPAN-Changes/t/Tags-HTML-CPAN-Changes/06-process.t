use strict;
use warnings;

use CPAN::Changes;
use CPAN::Changes::Entry;
use CPAN::Changes::Release;
use File::Object;
use Tags::HTML::CPAN::Changes;
use Tags::Output::Structure;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
);
$obj->init($changes);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],
		['b', 'h1'],
		['d', 'Revision history for perl module Foo::Bar'],
		['e', 'h1'],
		['e', 'div'],
	],
	'Tags code for CPAN changes (preamble).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
        'preamble' => '',
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],
		['e', 'div'],
	],
	'Tags code for CPAN changes (explicit blank preamble).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
	'releases' => [
		CPAN::Changes::Release->new(
			'date' => '2009-07-06',
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
				),
			],
			'version' => 0.01,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'h1'],
		['d', 'Revision history for perl module Foo::Bar'],
		['e', 'h1'],

		['b', 'div'],
		['a', 'class', 'version'],
		['b', 'h2'],
		['d', '0.01 - 2009-07-06'],
		['e', 'h2'],
		['b', 'ul'],
		['a', 'class', 'version-changes'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (preamble + one version with one item).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
	'releases' => [
		CPAN::Changes::Release->new(
			'date' => '2009-07-06',
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
				),
			],
			'version' => 0.01,
		),
		CPAN::Changes::Release->new(
			'date' => '2009-07-13',
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #2',
						'item #3',
					],
				),
			],
			'version' => 0.02,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],
		['b', 'h2'],
		['d', '0.02 - 2009-07-13'],
		['e', 'h2'],
		['b', 'ul'],
		['a', 'class', 'version-changes'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #2'],
		['e', 'li'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #3'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'div'],

		['b', 'div'],
		['a', 'class', 'version'],
		['b', 'h2'],
		['d', '0.01 - 2009-07-06'],
		['e', 'h2'],
		['b', 'ul'],
		['a', 'class', 'version-changes'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (two versions, one with 2 items).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Tags code for CPAN changes (no init).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
	'releases' => [
		CPAN::Changes::Release->new(
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
				),
			],
			'version' => 0.01,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],
		['b', 'h2'],
		['d', '0.01'],
		['e', 'h2'],
		['b', 'ul'],
		['a', 'class', 'version-changes'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (one version with one item without date).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
	'releases' => [
		CPAN::Changes::Release->new(
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
				),
			],
			'note' => 'Note about version',
			'version' => 0.01,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],
		['b', 'h2'],
		['d', '0.01 Note about version'],
		['e', 'h2'],
		['b', 'ul'],
		['a', 'class', 'version-changes'],
		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (one version with one item without date and with note).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
	'releases' => [
		CPAN::Changes::Release->new(
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
				),
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #2',
					],
					'text' => 'Foo',
				),
			],
			'version' => 0.01,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],

		['b', 'h2'],
		['d', '0.01'],
		['e', 'h2'],

		['b', 'ul'],
		['a', 'class', 'version-changes'],

		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],

		['b', 'h3'],
		['d', '[Foo]'],
		['e', 'h3'],

		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #2'],
		['e', 'li'],

		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (two items, one with group).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->new(
	'releases' => [
		CPAN::Changes::Release->new(
			'entries' => [
				CPAN::Changes::Entry->new(
					'entries' => [
						'item #1',
					],
					'text' => '',
				),
			],
			'version' => 0.01,
		),
	],
);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],

		['b', 'h2'],
		['d', '0.01'],
		['e', 'h2'],

		['b', 'ul'],
		['a', 'class', 'version-changes'],

		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'item #1'],
		['e', 'li'],

		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (one item, explicit blank group).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'tags' => $tags,
);
$changes = CPAN::Changes->load($data_dir->file('ex1.changes')->s);
$obj->init($changes);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'changes'],

		['b', 'div'],
		['a', 'class', 'version'],

		['b', 'h2'],
		['d', '0.01'],
		['e', 'h2'],

		['b', 'ul'],
		['a', 'class', 'version-changes'],

		['b', 'li'],
		['a', 'class', 'version-change'],
		['d', 'First version.'],
		['e', 'li'],

		['e', 'ul'],
		['e', 'div'],

		['e', 'div'],
	],
	'Tags code for CPAN changes (ex1.changes file).',
);
