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
	package RoleAttributes;

	use Moo::Role;
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
	package RoleHasAttributes;

	use Moo;
	use MooX::LazierAttributes;

	with 'RoleAttributes';

	has '+one'   => ( default => sub { 20 } );
	has '+two'   => ( default => sub { [qw/four five six/] } );
	has '+three' => ( default => sub { { three => 'four' } } );
	has '+four'  => ( default => sub { 'a different value' } );
	has '+five'  => ( default => sub { bless {}, 'Okays' } );
	has '+six'   => ( is_ro, default => sub { 1 } );
	has [qw/+eleven +twelve +thirteen/] => ( is_ro, default => sub { 'ahhhhhhhhhhhhh' } );

	sub _build_fourteen {
		return 40000;
	}

	1;
}

my $extends = RoleHasAttributes->new;

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

done_testing();
