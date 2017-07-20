use warnings;
use strict;

use Test::More tests => 26;

BEGIN { use_ok "Module::Runtime", qw(require_module); }

unshift @INC, "./t/lib";
my($result, $err);

sub test_require_module($) {
	my($name) = @_;
	$result = eval { require_module($name) };
	$err = $@;
}

# a module that doesn't exist
test_require_module("t::NotExist");
like($err, qr/^Can't locate /);

# a module that's already loaded
test_require_module("Test::More");
is($err, "");
is($result, 1);

# a module that we'll load now
test_require_module("t::Simple");
is($err, "");
is($result, "t::Simple return");

# re-requiring the module that we just loaded
test_require_module("t::Simple");
is($err, "");
is($result, 1);

# module file scope sees scalar context regardless of calling context
eval { require_module("t::Context"); 1 };
is $@, "";

# lexical hints don't leak through
my $have_runtime_hint_hash = "$]" >= 5.009004;
sub test_runtime_hint_hash($$) {
	SKIP: {
		skip "no runtime hint hash", 1 unless $have_runtime_hint_hash;
		is +((caller(0))[10] || {})->{$_[0]}, $_[1];
	}
}
SKIP: {
	skip "core bug makes this test crash", 13
		if "$]" >= 5.008 && "$]" < 5.008004;
	skip "can't work around hint leakage in pure Perl", 13
		if "$]" >= 5.009004 && "$]" < 5.010001;
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Module::Runtime/test_a"} = 1;
	is $^H{"Module::Runtime/test_a"}, 1;
	is $^H{"Module::Runtime/test_b"}, undef;
	require_module("t::Hints");
	is $^H{"Module::Runtime/test_a"}, 1;
	is $^H{"Module::Runtime/test_b"}, undef;
	t::Hints->import;
	is $^H{"Module::Runtime/test_a"}, 1;
	is $^H{"Module::Runtime/test_b"}, 1;
	eval q{
		BEGIN { $^H |= 0x20000; $^H{foo} = 1; }
		BEGIN { is $^H{foo}, 1; }
		main::test_runtime_hint_hash("foo", 1);
		BEGIN { require_module("Math::BigInt"); }
		BEGIN { is $^H{foo}, 1; }
		main::test_runtime_hint_hash("foo", 1);
		1;
	}; die $@ unless $@ eq "";
}

# broken module is visibly broken when re-required
eval { require_module("t::Break") };
like $@, qr/\A(?:broken |Attempt to reload )/;
eval { require_module("t::Break") };
like $@, qr/\A(?:broken |Attempt to reload )/;

# no extra eval frame
SKIP: {
	skip "core bug makes this test crash", 2 if "$]" < 5.006001;
	sub eval_test () { require_module("t::Eval") }
	eval_test();
}

1;
