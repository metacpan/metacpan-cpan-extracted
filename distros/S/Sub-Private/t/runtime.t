use strict;
use warnings;
use Test::Most;
no warnings 'once';

use File::Spec;
use File::Temp qw(tempdir);

# Loading Sub::Private, and the packages that use it, at run time (after
# CHECK has fired).  This file must NOT "use Sub::Private": the first
# require below is what loads it, after CHECK, exactly as a plugin loader
# would.

# The harness bypass would hide a leak.
delete $ENV{HARNESS_ACTIVE};

my $dir = tempdir(CLEANUP => 1);
unshift @INC, $dir;

my %fixtures = (
	# Attribute form, enforce mode.
	'RtAttr' => <<'EOF',
package RtAttr;
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;
sub new    { bless {}, shift }
sub _x :Private { 'attr' }
sub call_x { $_[0]->_x }
1;
EOF
	# Declarative form with the "use" line at the top, as usual.
	'RtDecl' => <<'EOF',
package RtDecl;
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private qw(_x _y);
sub new    { bless {}, shift }
sub _x     { 'decl' }
sub _y     { 'decl y' }
sub call_x { $_[0]->_x }
sub call_y { $_[0]->_y }
1;
EOF
	# Declarative form, import() called at the end of the file.
	'RtDeclEnd' => <<'EOF',
package RtDeclEnd;
BEGIN { $Sub::Private::config{mode} = 'enforce' }
sub new    { bless {}, shift }
sub _x     { 'decl end' }
sub call_x { $_[0]->_x }
use Sub::Private qw(_x);
1;
EOF
	# Declarative form naming a sub that never gets defined.
	'RtDeclMissing' => <<'EOF',
package RtDeclMissing;
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private qw(_missing);
1;
EOF
	# Attribute form, namespace mode.
	'RtNamespace' => <<'EOF',
package RtNamespace;
BEGIN { $Sub::Private::config{mode} = 'namespace' }
use Sub::Private;
sub _x :Private { 'ns' }
sub call_x { _x() }
1;
EOF
);

while (my ($name, $src) = each %fixtures) {
	my $file = File::Spec->catfile($dir, "$name.pm");
	open(my $fh, '>', $file) or die "$file: $!";
	print {$fh} $src;
	close($fh) or die "$file: $!";
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };
local $Sub::Private::BYPASS = 0;

ok(!$INC{'Sub/Private.pm'}, 'Sub::Private is not loaded before the first run-time require');

subtest 'attribute form, first load of Sub::Private after CHECK' => sub {
	ok(eval { require RtAttr; 1 }, 'require succeeds') or diag($@);
	my $obj = RtAttr->new();
	is($obj->call_x(), 'attr', 'callable from inside the owner package');
	throws_ok { $obj->_x() }
		qr/^_x\(\) is a private subroutine of RtAttr and cannot be called from main/,
		'blocked from outside';
};

subtest 'declarative form, use at the top of the file' => sub {
	ok(eval { require RtDecl; 1 }, 'require succeeds') or diag($@);
	my $obj = RtDecl->new();
	is($obj->call_x(), 'decl', '_x callable from inside');
	is($obj->call_y(), 'decl y', '_y callable from inside');
	throws_ok { $obj->_x() } qr/^_x\(\) is a private subroutine of RtDecl/, '_x blocked from outside';
	throws_ok { $obj->_y() } qr/^_y\(\) is a private subroutine of RtDecl/, '_y blocked from outside';
};

subtest 'declarative form, use at the end of the file' => sub {
	ok(eval { require RtDeclEnd; 1 }, 'require succeeds') or diag($@);
	my $obj = RtDeclEnd->new();
	is($obj->call_x(), 'decl end', 'callable from inside');
	throws_ok { $obj->_x() } qr/^_x\(\) is a private subroutine of RtDeclEnd/, 'blocked from outside';
};

subtest 'declarative form, undefined sub still croaks' => sub {
	ok(!eval { require RtDeclMissing; 1 }, 'require fails');
	like($@, qr/Sub::Private: RtDeclMissing::_missing is not defined/, 'with the usual message');
	like($@, qr/RtDeclMissing\.pm line 3\./, 'reported at the "use" line');
};

subtest 'string eval after CHECK' => sub {
	my $ok = eval q{
		package RtEval;
		use Sub::Private;
		sub _x :Private { 'eval' }
		sub call_x { _x() }
		1;
	};
	ok($ok, 'eval compiles') or diag($@);
	is(RtEval::call_x(), 'eval', 'callable from inside');
	throws_ok { RtEval::_x() } qr/^_x\(\) is a private subroutine of RtEval/, 'blocked from outside';
};

subtest 'run-time import() still wraps immediately' => sub {
	{
		package RtLate;
		no strict 'refs';
		*{'RtLate::_x'} = sub { 'late' };
		*{'RtLate::call_x'} = sub { RtLate::_x() };
		Sub::Private->import('_x');
	}
	is(RtLate::call_x(), 'late', 'callable from inside');
	throws_ok { RtLate::_x() } qr/^_x\(\) is a private subroutine of RtLate/, 'blocked from outside';
};

subtest 'namespace mode, attribute form' => sub {
	ok(eval { require RtNamespace; 1 }, 'require succeeds') or diag($@);
	is(RtNamespace::call_x(), 'ns', 'callable directly from inside');
	ok(!RtNamespace->can('_x'), 'removed from method lookup');
	$Sub::Private::config{mode} = 'enforce';
};

is_deeply(\@warnings, [], 'no warnings from loading after CHECK')
	or diag(explain(\@warnings));

done_testing();
