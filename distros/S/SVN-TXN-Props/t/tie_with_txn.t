# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-TXN-Props.t'

#########################

use strict;
use warnings;
use Test::More tests => 32;
use Test::MockClass qw(SVN::Core SVN::Fs SVN::Repos);
BEGIN { use_ok('SVN::TXN::Props', qw(get_txn_props)) };

#########################

my %changed_props;
my $test_props = { 'svn:prop' => 'value' };
my $mockSVNTxnClass = Test::MockClass->new('_p_svn_fs_txn_t');
$mockSVNTxnClass->defaultConstructor();
$mockSVNTxnClass->setReturnValues('proplist', 'always', $test_props);
$mockSVNTxnClass->addMethod('change_prop',
	sub {
		$changed_props{$_[1]} = $_[2];
	});
my $mockTxn = $mockSVNTxnClass->create();

my %props;
tie %props, 'SVN::TXN::Props', $mockTxn;
is(scalar keys %props, 1);
is($props{'svn:prop'}, 'value');
is(scalar keys %changed_props, 0);

$props{'svn:newprop'} = 'newvalue';
is(scalar keys %props, 2);
is($props{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 1);
is($changed_props{'svn:newprop'}, 'newvalue');

$props{'svn:prop'} = 'othervalue';
is(scalar keys %props, 2);
is($props{'svn:prop'}, 'othervalue');
is($props{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 2);
is($changed_props{'svn:prop'}, 'othervalue');
is($changed_props{'svn:newprop'}, 'newvalue');

delete $props{'svn:prop'};
is(scalar keys %props, 1);
is(scalar keys %changed_props, 2);
ok(exists $changed_props{'svn:prop'});
is($changed_props{'svn:prop'}, undef);
is($changed_props{'svn:newprop'}, 'newvalue');

$props{'svn:prop'} = 'othervalue';
is(scalar keys %props, 2);
is($props{'svn:prop'}, 'othervalue');
is($props{'svn:newprop'}, 'newvalue');
is(scalar keys %changed_props, 2);
is($changed_props{'svn:prop'}, 'othervalue');
is($changed_props{'svn:newprop'}, 'newvalue');

%props = ();
is(scalar keys %props, 0);
is(scalar keys %changed_props, 2);
ok(exists $changed_props{'svn:prop'});
ok(exists $changed_props{'svn:newprop'});
is($changed_props{'svn:prop'}, undef);
is($changed_props{'svn:newprop'}, undef);

eval {
	my %props2;
	tie %props2, 'SVN::TXN::Props', undef;
	fail("should have croaked");
};
ok(defined $@);

1;
