use Test::More;

BEGIN {
    eval {
	    require Moo;
        require Type::Tiny;
        1;
    } or do {
        plan skip_all => "Cannot require Moo or Type::Tiny";
    };
}

{
	package BasicTypes;

	use Moo;
	use MooX::LazierAttributes;
	use Types::Standard qw/Str HashRef ArrayRef Object/;

	attributes (
		not => [ Str ],
		[qw/sorry okay/] => [ rw, HashRef, { default => { one => 'two' } } ],
		another => [rw, HashRef, { lzy_hash }],
		object => [ ro, Object, { bld } ],
	);

	sub _build_object{
		return bless {}, 'Thing';
	}

	has thing => (
		is_rw,
		isa => Str,
	);

	has why => (
		is_ro,
		isa => HashRef,
	);

	has care => (
		is_ro,
		isa => ArrayRef,
	);

	1;
}

use BasicTypes;
use lib '.';

my $basics = BasicTypes->new;

ok($basics->thing('okay'));
is($basics->thing, 'okay');
eval { $basics->thing({ ohhh => 'noooo' }) };
my $error = $@;
my $expected_error = 'Reference {"ohhh" => "noooo"} did not pass type constraint "Str" (in $self->{"thing"})';
is($error->message, $expected_error, "caugt an error - ${expected_error}");

is_deeply($basics->sorry, { one => 'two' }, "we have a set hashref");
is_deeply($basics->okay, { one => 'two' }, "we have a set hashref");

ok($basics->sorry({ three => 'four' }, "set sorry"));
ok($basics->okay({ three => 'four' }, "set sorry"));

is_deeply($basics->sorry, { three => 'four' }, "sorry was set");
is_deeply($basics->okay, { three => 'four' }, "okay was set");

is_deeply($basics->another, { }, "lazy hash");

isa_ok($basics->object, 'Thing');
done_testing();
