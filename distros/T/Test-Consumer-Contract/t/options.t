#!/usr/bin/env perl

# What new() accepts and refuses, what it does to @INC, how it takes the
# configuration, and the access rules on the subs it does not publish.  A
# declaration is code someone wrote; each refusal here is a mistake that used to
# surface later, further from where it was made, or not at all.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::Consumer::Contract;

# The smallest declaration new() accepts.
my %MINIMAL = (source => 'S', guaranteed => [], methods => []);

subtest 'a declaration can be a list of pairs or one hashref' => sub {
	isa_ok(Test::Consumer::Contract->new(%MINIMAL), 'Test::Consumer::Contract', 'from pairs');
	isa_ok(Test::Consumer::Contract->new({ %MINIMAL }), 'Test::Consumer::Contract', 'from a hashref');
};

subtest 'an optional option given as undef takes its default' => sub {
	# Stored as undef, these were dereferenced later and run() died with
	# "Can't use an undefined value as a HASH reference".
	my $contract = Test::Consumer::Contract->new(%MINIMAL, map { $_ => undef }
		qw(consumers conditional producers ignored accessors not_accessors messages value_object));

	is_deeply($contract->{'consumers'}, {}, 'a hash option is an empty hash');
	is_deeply($contract->{'ignored'}, [], 'a list option is an empty list');
	is($contract->{'value_object'}, undef, 'and value_object stays absent');
	lives_ok { $contract->i18n('check.producers') } 'the messages default is usable';
};

subtest 'an option of the wrong type is refused' => sub {
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, methods => 'geocode') }
		qr/::new\(\): .*methods/, 'methods has to be a list';
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, conditional => ['colour']) }
		qr/::new\(\): .*conditional/, 'conditional has to be a hash';
};

subtest 'an ignored rule has to be [prefix, reason]' => sub {
	# A bare string used to be passed over without a word, so the file it was
	# meant to ignore was reported as an unregistered consumer instead.
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, ignored => ['Widget-List/']) }
		qr/each 'ignored' rule must be \[prefix, reason\], not Widget-List\//, 'a bare string';
	lives_ok { Test::Consumer::Contract->new(%MINIMAL, ignored => [['Widget-List/', 'why']]) } 'a pair';
	lives_ok { Test::Consumer::Contract->new(%MINIMAL, ignored => [['Widget-List/']]) } 'a prefix alone';
};

subtest 'a consumer entry has to be shaped as check 3 reads it' => sub {
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, consumers => { 'A/x.pm' => 1 }) }
		qr/consumer 'A\/x\.pm' must be/, 'not a hash';
	throws_ok {
		Test::Consumer::Contract->new(%MINIMAL, consumers => { 'A/x.pm' => { may_rely_on => { render => 'colour' } } })
	} qr/consumer 'A\/x\.pm' must be/, 'a sub that maps to a string rather than to keys';
	lives_ok { Test::Consumer::Contract->new(%MINIMAL, consumers => { 'A/x.pm' => {} }) }
		'an entry with nothing to rely on';
};

subtest 'the value object is named by a module name' => sub {
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, value_object => { from => {} }) }
		qr/value_object needs a 'class' that is a module name, not 'undef'/, 'no class';
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, value_object => { class => '../../etc/passwd' }) }
		qr/not '\.\.\/\.\.\/etc\/passwd'/, 'a path is not handed to require';
};

subtest 'an explicit root has to be a directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $missing = File::Spec->catdir($dir, 'No-Such-Distribution');

	throws_ok { Test::Consumer::Contract->new(%MINIMAL, dist_root => $missing) }
		qr/dist_root '\Q$missing\E' is not a directory: /, 'dist_root';
	throws_ok { Test::Consumer::Contract->new(%MINIMAL, workspace => $missing) }
		qr/workspace '\Q$missing\E' is not a directory: /, 'workspace';
};

subtest 'an include directory is put in @INC once, however many contracts name it' => sub {
	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'Widget-Maker', 'lib'));
	my $lib = File::Spec->catdir($dir, 'Widget-Maker', 'lib');

	local @INC = @INC;
	Test::Consumer::Contract->new(%MINIMAL, workspace => $dir, include => ['Widget-Maker/lib']) for 1 .. 3;

	is(scalar(grep { $_ eq $lib } @INC), 1, 'one entry') or diag(explain(\@INC));
	is($INC[0], $lib, 'at the front');
};

subtest 'an object keeps the configuration it was built with' => sub {
	my $before = Test::Consumer::Contract->new(%MINIMAL);

	local $Test::Consumer::Contract::config{'sibling_dirs'} = ['lib'];
	my $after = Test::Consumer::Contract->new(%MINIMAL);

	is_deeply($before->{'config'}{'sibling_dirs'}, [qw(lib bin t)], 'an earlier object is unchanged');
	is_deeply($after->{'config'}{'sibling_dirs'}, ['lib'], 'a later one takes the change');
};

subtest 'run() and the checks chain' => sub {
	my $contract = Test::Consumer::Contract->new(%MINIMAL, require_workspace => ['No-Such-Distribution']);

	# Only discovery applies to this declaration, and it skips: the result of
	# run() is still the object, for chaining.
	is($contract->run(), $contract, 'run() returns the object');
};

subtest 'the private and protected subs are not part of the interface' => sub {
	my $contract = Test::Consumer::Contract->new(%MINIMAL);

	# Both modules let a test harness through; turned off here, so the rule
	# that holds outside a harness is the one being tested.
	local $Sub::Private::config{'harness_bypass'} = 0;
	local $Sub::Protected::config{'harness_bypass'} = 0;
	local $Sub::Private::BYPASS = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok { $contract->_program(__FILE__) } qr/private subroutine of Test::Consumer::Contract/,
		'a private sub refuses another package';
	throws_ok { $contract->_check_producers() } qr/protected method of Test::Consumer::Contract/,
		'a protected sub refuses a package that is not a subclass';

	{
		package My::Contract;
		our @ISA = ('Test::Consumer::Contract');
		sub producers { return $_[0]->_check_producers() }
	}
	my $sub = My::Contract->new(%MINIMAL);
	is($sub->producers(), $sub, 'a subclass may call a protected check');
};

done_testing();
