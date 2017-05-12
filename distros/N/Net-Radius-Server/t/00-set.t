use Test::More tests => 42;

package My::Set;
use Test::More;
use Net::Radius::Server::Base qw/:set/;
use base 'Net::Radius::Server::Set';
__PACKAGE__->mk_accessors(qw/foo bar baz/);

package main;
use Net::Radius::Server::Base qw/:set/;

# Simple constant tests
is(NRS_SET_CONTINUE,	0, 'Constant NRS_SET_CONTINUE');
is(NRS_SET_SKIP,	1, 'Constant NRS_SET_SKIP');
is(NRS_SET_RESPOND,	2, 'Constant NRS_SET_RESPOND');
is(NRS_SET_DISCARD,	4, 'Constant NRS_SET_DISCARD');

# Class hierarchy
my $m = new My::Set;
isa_ok($m, 'Exporter');
isa_ok($m, 'Class::Accessor');
isa_ok($m, 'Net::Radius::Server');
isa_ok($m, 'Net::Radius::Server::Set');

can_ok($m, 'new');
can_ok($m, 'log');
can_ok($m, 'log_level');
can_ok($m, 'mk');
can_ok($m, '_set');

# Test the ->description facility
can_ok($m, 'description');
like($m->description, qr/My::Set/, "Description contains the class");
like($m->description, qr/\([^:]+:/, "Description contains the filename");
like($m->description, qr/:\d+\)$/, "Description contains the line");

# This initialization should be fine
can_ok($m, 'foo') and $m->foo('Foo');
can_ok($m, 'bar') and $m->bar('Bar');
can_ok($m, 'baz') and $m->baz('Baz');

# Now test the factory
my $method = $m->mk();
is(ref($method), "CODE", "Factory returns a coderef/sub");

# Invocation without any hooks should return CONTINUE...
is($method->(), NRS_SET_CONTINUE, "Set with no hooks...");

# Add the result hook and verify this is used
package My::Set;
__PACKAGE__->mk_accessors(qw/result/);

package main;
$m->result(42);
is($method->(), 42, "Set with result hook...");

# Test ignoring of "_" properties
package My::Set;
our $Fail = 0;
__PACKAGE__->mk_accessors(qw/_ignore/);
sub set__ignore
{
    diag('This invocation is wrong!!!');
    ++$Fail;
    return NRS_SET_DISCARD;
}

package main;
$method = My::Set->mk({foo => 'Foo', bar => 'Bar', baz => 'Baz', 
			 _ignore => 'Oops'});
is($My::Set::Fail, 0, "_ hook handler must not be called");

# Test the processing of the handlers
package My::Set;
sub set_foo { $_[1]->{foo} ++; $_[1]->{queue} .= $_[0]->foo }
sub set_bar { $_[1]->{bar} ++; $_[1]->{queue} .= $_[0]->bar }
sub set_baz { $_[1]->{baz} ++; $_[1]->{queue} .= $_[0]->baz }

package main;

$method = $m->mk();
can_ok($m, 'foo') and $m->foo('Foo');
can_ok($m, 'bar') and $m->bar('Bar');
can_ok($m, 'baz') and $m->baz('Baz');

my %data = ( foo => 0, bar => 0, baz => 0, queue => '' );
is($method->(\%data), $m->result, "Invocation of method with hooks");
is($data{foo}, 1, "set_foo invoked");
is($data{bar}, 1, "set_bar invoked");
is($data{baz}, 1, "set_baz invoked");
like($data{queue}, qr/Foo/, 'set_foo worked');
like($data{queue}, qr/Bar/, 'set_bar worked');
like($data{queue}, qr/Baz/, 'set_baz worked');

# Test that invocations only happen when the attribute exists
$m = My::Set->new({foo => 'Foo', bar => 'Bar', result => '6x9' });
$method = $m->mk;

%data = ( foo => 0, bar => 0, baz => 0, queue => '' );
is($method->(\%data), $m->result, "Invocation of method with hooks");
is($data{foo}, 1, "set_foo invoked");
is($data{bar}, 1, "set_bar invoked");
is($data{baz}, 0, "set_baz not invoked");
like($data{queue}, qr/Foo/, 'set_foo worked');
like($data{queue}, qr/Bar/, 'set_bar worked');
unlike($data{queue}, qr/Baz/, 'set_baz not invoked');

# Verify that the result hook will be called if defined...
eval q{
package My::Set;
sub set_result { $_[0]->result('6x9=42') }
};

is($method->(\%data), '6x9=42', 'Dynamic result hook is called when defined');

