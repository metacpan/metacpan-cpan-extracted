use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
	    require Moo;
        require Type::Tiny;
        1;
    } or do {
        plan skip_all => "Cannot Require Moo or Type::Tiny";
    };
}

{
	package HasAttributes;

	use Moo;
	use MooX::LazierAttributes;

	has one   => ( is_rw, default => sub { 10 } );
	has two   => ( is_ro, default => sub { [qw/one two three/] } );
	has three => ( is_ro, default => sub { { one => 'two' } } );
	has four  => ( is_ro, default => sub { 'a default value' } );
	has five  => ( is_ro, default => sub { bless {}, 'Thing' } );
	has six   => ( is_ro, default => sub { 0 } );
	has seven => ( is_ro, default => sub { undef } );
	has eight => ( is_rw );
	has nine  => ( is_ro, lzy, default => sub { { broken => 'thing' } } );
	has ten   => ( is_rw, default => sub { {} } );
	has [qw/eleven twelve thirteen/] => ( is_ro, default => sub { 'test this' } );
	has fourteen => ( is_rw, bld, clr, lzy );
	sub _build_fourteen {
		return 100;
	}

	1;
}

{
	package ExtendsHasAttributes;

	use Moo;
	use MooX::LazierAttributes;

	extends 'HasAttributes';

	has '+one'   => ( default => sub { 20 } );
	has '+two'   => ( default => sub { [qw/four five six/] } );
	has '+three' => ( default => sub { { three => 'four' } } );
	has '+four'  => ( default => sub { 'a different value' } );
	has '+five'  => ( default => sub { bless {}, 'Okays' } );
	has six   => ( is_ro, default => sub { 1 } );
	has [qw/+eleven +twelve +thirteen/] => ( is_ro, default => sub { 'ahhhhhhhhhhhhh' } );
	has fifthteen => (is_ro, lzy_array);
	
	sub _build_fourteen {
		return 40000;
	}

	1;
}

my $basics = HasAttributes->new;

is($basics->one, 10, 'okay we got 10');
is_deeply($basics->two, [qw/one two three/], 'is deeply');
is_deeply($basics->three, { one => 'two' }, 'is deeply');
is($basics->four, 'a default value', 'a default value');
isa_ok($basics->five, 'Thing');
is($basics->six, 0, "a false value");
is($basics->seven, undef, "undef value");
is($basics->eight, undef, "undef value");
is_deeply($basics->nine, { 'broken' => 'thing' }, 'fix my broken code');
is_deeply($basics->ten, {}, 'fix my broken code');
is_deeply($basics->eleven, 'test this', 'arrayref of names - eleven');
is_deeply($basics->twelve, 'test this', 'arrayref of names - twelve');
is_deeply($basics->thirteen, 'test this', 'arrayref of names - thirteen');
is($basics->fourteen, 100, 'okay 100');
ok($basics->fourteen(50), 'set 50');
is($basics->fourteen, 50, 'okay 50');
ok($basics->clear_fourteen, 'clear fourteen');
is($basics->fourteen, 100, 'okay 100');

my $extends = ExtendsHasAttributes->new;

is($extends->one, 20, 'okay we got 20');
is_deeply($extends->two, [qw/four five six/], 'is deeply');
is_deeply($extends->three, { three => 'four' }, 'is deeply');
is($extends->four, 'a different value', 'a default value');
isa_ok($extends->five, 'Okays');
is($extends->six, 1, "a true value");
is($extends->seven, undef, "undef value");
is($extends->eight, undef, "undef value");
is_deeply($extends->eleven, 'ahhhhhhhhhhhhh', 'arrayref of names - eleven');
is_deeply($extends->twelve, 'ahhhhhhhhhhhhh', 'arrayref of names - twelve');
is_deeply($extends->thirteen, 'ahhhhhhhhhhhhh', 'arrayref of names - thirteen');
is($extends->fourteen, 40000, 'okay 100');
is_deeply($extends->fifthteen, [], 'okay []');
done_testing();
