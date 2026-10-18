#!/usr/bin/env perl

# The message catalogue: every test name, diagnostic and error goes through
# i18n(), so these are the rules the text a user reads is made by.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::Most;
use Test::Consumer::Contract;

my %MINIMAL = (source => 'S', guaranteed => [], methods => []);

my $contract = Test::Consumer::Contract->new(%MINIMAL);

subtest 'a key gives its English text, with the placeholders filled in' => sub {
	is($contract->i18n('check.producers'), 'the producers still set the keys the contract claims', 'no arguments');
	is($contract->i18n('producer.sets', { file => 'lib/A.pm', key => 'x' }), "lib/A.pm sets 'x'", 'two arguments');
	is(Test::Consumer::Contract->i18n('why.unpromised'), 'no producer in this workspace ever sets it',
		'and as a class method');
	like($contract->i18n('option.unknown', { options => 'x' }), qr/\ATest::Consumer::Contract::new\(\)/,
		'the package is filled in for the caller');
};

subtest 'a placeholder is formatted, joined, or left as written' => sub {
	my $templated = Test::Consumer::Contract->new(%MINIMAL, messages => {
		'test.format'  => '{n:%03d} of {total:%.1f}',
		'test.list'    => 'missing: {names}',
		'test.unknown' => 'hello {who}',
		'test.unsafe'  => 'count {n:%n}',
	});

	is($templated->i18n('test.format', { n => 7, total => 9 }), '007 of 9.0', 'a sprintf conversion');
	is($templated->i18n('test.list', { names => [qw(a b)] }), 'missing: a, b', 'an arrayref is joined');
	is($templated->i18n('test.unknown'), 'hello {who}', 'a placeholder with no value shows');
	is($templated->i18n('test.unknown', { who => undef }), 'hello ', 'an undef value is empty');
	is($templated->i18n('test.unsafe', { n => 1 }), 'count {n:%n}', '%n is never handed to sprintf');
};

subtest 'a hash of forms is chosen by count, and by context before count' => sub {
	my $forms = Test::Consumer::Contract->new(%MINIMAL, messages => {
		'test.plural' => { zero => 'no files', one => 'one file', other => '{count} files' },
		'test.gender' => { female => 'she reads it', male => 'he reads it', other => 'they read it' },
	});

	is($forms->i18n('test.plural', { count => 0 }), 'no files', 'zero');
	is($forms->i18n('test.plural', { count => 1 }), 'one file', 'one');
	is($forms->i18n('test.plural', { count => 3 }), '3 files', 'other');
	is($forms->i18n('test.plural', {}), '{count} files', 'no count is other');
	is($forms->i18n('test.gender', { context => 'female' }), 'she reads it', 'a context');
	is($forms->i18n('test.gender', { context => 'unknown' }), 'they read it', 'an unknown context is other');

	# The built-in catalogue uses it too: one unregistered file, or several.
	like($contract->i18n('discovery.advice', { count => 1 }), qr/\ARegister it /, 'built-in, one');
	like($contract->i18n('discovery.advice', { count => 2 }), qr/\ARegister each /, 'built-in, other');
};

subtest 'the object wins over the configuration, which wins over the built-in' => sub {
	local $Test::Consumer::Contract::config{'messages'}{'check.producers'} = 'die Erzeuger';

	my $own = Test::Consumer::Contract->new(%MINIMAL, messages => { 'check.producers' => 'les producteurs' });

	is($own->i18n('check.producers'), 'les producteurs', 'the object\'s own wording');
	is($contract->i18n('check.producers'), 'die Erzeuger', 'the configured wording, for any object');
	is(Test::Consumer::Contract->i18n('check.producers'), 'die Erzeuger', 'and for the class');
};

subtest 'an error is worded by the catalogue too' => sub {
	local $Test::Consumer::Contract::config{'messages'}{'option.required'} = "'{option}' fehlt";

	throws_ok { Test::Consumer::Contract->new(source => 'S', guaranteed => []) } qr/\A'methods' fehlt at /,
		'the configured text, reported from the caller';
};

subtest 'a key in no catalogue is a bug, and says where it was asked for' => sub {
	throws_ok { $contract->i18n('no.such.key') } qr/no message called 'no\.such\.key'.*i18n\.t/s,
		'confessed with the stack';
	throws_ok { $contract->i18n() } qr/i18n\(\) needs a 'key'/, 'a missing key';
	throws_ok { $contract->i18n('check.producers', 'not a hash') } qr/i18n\(\)/, 'arguments that are not a hash';
};

done_testing();
