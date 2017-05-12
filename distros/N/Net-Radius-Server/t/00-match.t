use Test::More tests => 53;

package My::Match;
use Test::More;
use Net::Radius::Server::Base qw/:match/;
use base 'Net::Radius::Server::Match';
__PACKAGE__->mk_accessors(qw/foo bar baz/);

package main;
use Net::Radius::Server::Base qw/:all/;

# Simple constant tests
is(NRS_MATCH_FAIL,	0, 'Constant NRS_MATCH_FAIL');
is(NRS_MATCH_OK,	1, 'Constant NRS_MATCH_OK');

is(NRS_SET_CONTINUE,	0, 'Constant NRS_SET_CONTINUE');
is(NRS_SET_SKIP,	1, 'Constant NRS_SET_SKIP');
is(NRS_SET_RESPOND,	2, 'Constant NRS_SET_RESPOND');
is(NRS_SET_DISCARD,	4, 'Constant NRS_SET_DISCARD');

# Class hierarchy
my $m = new My::Match;
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Match');

can_ok($m, 'mk');
can_ok($m, 'new');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, '_match');		# Not strictly required, but can help

# Test the accessors
can_ok($m, 'description');

# Test the ->description facility
like($m->description, qr/My::Match/, "Description contains the class");
like($m->description, qr/\([^:]+:/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

# This initialization should be fine
can_ok($m, 'foo') and $m->foo('Foo');
can_ok($m, 'bar') and $m->bar('Bar');
can_ok($m, 'baz') and $m->baz('Baz');

$m->log_level(-1);

# Now test the factory
my $method = $m->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation without any match hook should return true...
is($method->(), NRS_MATCH_OK, "Match with no hooks...");

# Define the first match hook
eval q{
    sub My::Match::match_foo
    {
	ok('Invocation of match_foo');
	return NRS_MATCH_FAIL unless $_[0]->foo eq 'Foo';
	return NRS_MATCH_OK;
    }
};
is($method->(), NRS_MATCH_OK, "Match with hook for foo...");

# 2nd match hook
eval q{
    sub My::Match::match_bar
    {
	ok('Invocation of match_bar');
	return NRS_MATCH_FAIL unless $_[0]->bar eq 'Bar';
	return NRS_MATCH_OK;
    }
};
is($method->(), NRS_MATCH_OK, "Match with hooks for foo & bar...");

# 3rd match hook
eval q{
    sub My::Match::match_baz
    {
	ok('Invocation of match_baz');
	return NRS_MATCH_FAIL unless $_[0]->baz eq 'Baz';
	return NRS_MATCH_OK;
    }
};
is($method->(), NRS_MATCH_OK, "Match with hooks for foo, bar & baz...");

# Now, tweak the result using the object we kept
$m->bar('Bad');
is($method->(), NRS_MATCH_FAIL, "Match after changing the master object...");

# Test the factory directly
$method = My::Match->mk({foo => 'Foo', bar => 'Bar', baz => 'Baz',
			 log_level => -1});
is($method->(), NRS_MATCH_OK, "Direct factory match...");
$method = My::Match->mk({foo => 'Foo', bar => 'Bar', baz => 'Bad',
			 log_level => -1});
is($method->(), NRS_MATCH_FAIL, "Direct factory match...");
$method = My::Match->mk({foo => 'Foo', bar => 'Bad', baz => 'Baz',
			 log_level => -1});
is($method->(), NRS_MATCH_FAIL, "Direct factory match...");
$method = My::Match->mk({foo => 'Food', bar => 'Bar', baz => 'Baz',
			 log_level => -1});
is($method->(), NRS_MATCH_FAIL, "Direct factory match...");

# Test ignoring of "_" properties
package My::Match;
our $Fail = 0;
__PACKAGE__->mk_accessors(qw/_ignore/);
sub match__ignore
{
    fail('Invocation of called _ method hook');
    ++$Fail;
    return NRS_MATCH_FAIL;
}

package main;
$method = My::Match->mk({foo => 'Foo', bar => 'Bar', baz => 'Baz', 
			 _ignore => 'Oops', log_level => -1});
is($method->(), NRS_MATCH_OK, "Match with _ hook");
is($My::Match::Fail, 0, "Should not call _ hook handler");

