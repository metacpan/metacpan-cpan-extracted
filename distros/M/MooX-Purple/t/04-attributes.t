use strict;
use warnings;
use Test::More;
use MooX::Purple;
use MooX::Purple::G 't/lib';

class BasicAttributes {
	attributes (
		one      => [ 10 ],    
		two      => [ ro, [qw/one two three/] ],    
		three    => [ 'ro', { one => 'two' } ],    
		four     => [ 'ro', 'a default value' ],
		five     => [ 'ro', bless {}, 'Thing' ],
		six      => [ 'ro', 0 ],
		seven    => [ 'ro', undef ],
		eight    => [ 'rw' ],
		nine     => [ ro, { broken => 'thing' }, { lzy } ],
		ten      => [ 'rw', {}],
		[qw/eleven twelve thirteen/] => [ro, 'test this'],
		fourteen => [ rw, nan, { bld, clr, lzy } ],
		fifthteen => [ sub { { correct => 'way' } } ],
	);

	sub _build_fourteen {
		return 100;
	}
}

class ExtendsBasicAttributes is BasicAttributes{
	attributes (    
		'+one'   => [ 20 ],
		'+two'   => [ [qw/four five six/]],
		'+three' => [ { three => 'four' }],
		'+four'  => [ 'a different value'],
		'+five'  => [ bless {}, 'Okays'],
		six      => [ ro, 1 ],
		'+seven' => [ nan, { lzy } ],
		[qw/+eleven +twelve +thirteen/] => ['ahhhhhhhhhhhhh']
	);

	sub _build_fourteen {
		return 40000;
	}
}

my $basics = BasicAttributes->new;

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
is_deeply($basics->fifthteen, { correct => 'way' }, 'okay the correct way');

my $extends = ExtendsBasicAttributes->new;

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
is_deeply($basics->fifthteen, { correct => 'way' }, 'okay the correct way');

done_testing();
