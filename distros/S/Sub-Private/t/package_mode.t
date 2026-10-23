use strict;
use warnings;
use Test::Most;
no warnings 'once';

use File::Spec;
use File::Temp qw(tempdir);

# use Sub::Private { mode => ... } chooses the mode for one package and
# leaves the global $Sub::Private::config{mode}, and so every other
# package, alone.  This file sets no global mode, so it stays 'namespace'.

use Sub::Private;

# Enforce mode for this package only, attribute form.
{
	package PmEnforce;
	use Sub::Private { mode => 'enforce' };

	sub new { bless {}, shift }
	sub _x :Private { 'enforced' }
	sub call_x { $_[0]->_x }
}

# No mode of its own: the global mode, namespace, applies.
{
	package PmDefault;
	use Sub::Private;

	sub _x :Private { 'cleaned' }
	sub call_x { _x() }
}

# Enforce mode for this package, declarative form.
{
	package PmDecl;
	use Sub::Private { mode => 'enforce' }, qw(_y);

	sub new { bless {}, shift }
	sub _y { 'declared' }
	sub call_y { $_[0]->_y }
}

{
	package PmOutsider;
	sub probe_x { PmEnforce->new->_x }
	sub probe_y { PmDecl->new->_y }
}

local $ENV{HARNESS_ACTIVE} = 0;
local $Sub::Private::BYPASS = 0;

is($Sub::Private::config{mode}, 'namespace', 'the global mode is left as it was');

subtest 'a package that chose enforce mode' => sub {
	is(PmEnforce->new->call_x, 'enforced', 'the owner can call its private method');
	throws_ok { PmOutsider::probe_x() }
		qr/\Q_x() is a private subroutine of PmEnforce and cannot be called from PmOutsider\E/,
		'another package cannot';
	ok(PmEnforce->can('_x'), 'the sub was wrapped, not removed');
};

subtest 'a package that chose nothing' => sub {
	is(PmDefault::call_x(), 'cleaned', 'calls compiled before CHECK still work');
	ok(!PmDefault->can('_x'), 'the sub was removed, as namespace mode does');
};

subtest 'the declarative form with a mode' => sub {
	is(PmDecl->new->call_y, 'declared', 'the owner can call its private method');
	throws_ok { PmOutsider::probe_y() }
		qr/\Q_y() is a private subroutine of PmDecl and cannot be called from PmOutsider\E/,
		'another package cannot, though the global mode is namespace';
};

subtest 'bad options are refused' => sub {
	throws_ok { package PmBad1; Sub::Private->import({ colour => 'red' }) }
		qr/\QSub::Private->import: unknown option 'colour'\E/, 'an unknown option';
	throws_ok { package PmBad2; Sub::Private->import({ mode => 'strict' }) }
		qr/\QSub::Private: unknown mode 'strict'\E/, 'an unknown mode';
	throws_ok { package PmBad3; Sub::Private->import({ mode => undef }) }
		qr/\QSub::Private: unknown mode ''\E/, 'an undefined mode';
	throws_ok { package PmBad4; Sub::Private->import({ mode => 'namespace' }, '_z') }
		qr/declarative form requires mode => 'enforce'/,
		'the declarative form with namespace mode';
	throws_ok { package PmBad5; Sub::Private->import({ mode => 'enforce', colour => 'red' }) }
		qr/unknown option 'colour'/, 'a good option does not excuse a bad one';
	throws_ok { package PmBad5; Sub::Private->import(qw(_z)) }
		qr/declarative form requires mode => 'enforce'/,
		'and the package mode was not set by it';
	is($Sub::Private::config{mode}, 'namespace', 'the global mode is still unchanged');
};

# Attribute::Handlers was loaded at compile time here, so for a package
# loaded at run time it calls the handler for the CHECK phase straight away,
# before the sub is installed.  Up to 0.06 namespace mode then removed the
# half-compiled sub, and the package's own direct calls died with
# "Undefined subroutine".
subtest 'a package that chose namespace while the global mode is enforce' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'PmNamespace.pm');
	open(my $fh, '>', $file) or die "$file: $!";
	print {$fh} <<'EOF';
package PmNamespace;
use Sub::Private { mode => 'namespace' };
sub _x :Private { 'ns' }
sub call_x { _x() }
1;
EOF
	close($fh) or die "$file: $!";

	local @INC = ($dir, @INC);
	local $Sub::Private::config{mode} = 'enforce';
	require PmNamespace;

	is(PmNamespace::call_x(), 'ns', 'the package can still call it');
	ok(!PmNamespace->can('_x'), 'the package mode wins: the sub was removed');
};

subtest 'loaded at run time with enforce mode' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'PmRuntime.pm');
	open(my $fh, '>', $file) or die "$file: $!";
	print {$fh} <<'EOF';
package PmRuntime;
use Sub::Private { mode => 'enforce' };
sub new { bless {}, shift }
sub _x :Private { 'runtime' }
sub call_x { $_[0]->_x }
1;
EOF
	close($fh) or die "$file: $!";

	local @INC = ($dir, @INC);
	require PmRuntime;

	is(PmRuntime->new->call_x, 'runtime', 'the owner can call its private method');
	throws_ok { PmRuntime->new->_x }
		qr/\Q_x() is a private subroutine of PmRuntime and cannot be called from main\E/,
		'another package cannot';
	is($Sub::Private::config{mode}, 'namespace', 'the global mode is unchanged');
	ok(!defined(&main::ANON), 'no stray wrapper is left in main::ANON');
};

done_testing();
