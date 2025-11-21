use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moo'; use Test::Requires 'MooX::TypeTiny'; };

our $modified_GenerateAccessor = !!0;

{
        package TestRole;
        use Devel::StackTrace;
        use Moo::Role;

        # test that at some point in the calling chain the modified
        # _generate_isa_check routine in
        # MooX::TypeTiny::Role::GenerateAccessor was involved.  this
        # depends upon internal knowledge of MooX::TypeTiny.  This
        # guards against the possibility that Sub::HandlesVia is
        # subverting the actions of MooX::TypeTiny, as there is no
        # difference in behavior between MooX::TypeTiny silently being
        # ignored and it working.

        around  inline_assert => sub {
          my $level = 0;
          while ( my @caller = caller(++$level ) ) {
             $::modified_GenerateAccessor ||= $caller[0] eq 'MooX::TypeTiny::Role::GenerateAccessor';
          }
          my $orig = shift;
          $orig->(@_);
        };

}

note 'Local::Bleh';
{
	package Local::Bleh;
	use Moo;
	use MooX::TypeTiny;
	use Types::Standard -types;
	use Sub::HandlesVia;

        my $check = ArrayRef[ Int->plus_coercions(Num, 'int($_)') ];
        Moo::Role->apply_roles_to_object( $check, 'TestRole');

	has nums => (
		is           => 'lazy',
		isa          => $check,
		coerce       => 1,
		builder      => sub { [1..2] },
		handles_via  => 'Array',
		handles      => {
			splice_nums     => 'splice',
			splice_nums_tap => 'splice...',
			first_num       => [ 'get', 0 ],
		},
	);
}

my $bleh = Local::Bleh->new;

ok( $modified_GenerateAccessor, 'MooX::Type::Tiny::Role::GenarateAccessor was applied'  );

my @r = $bleh->splice_nums(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method worked');
is_deeply(\@r, [1..2], '... and returned correct value');
is($bleh->first_num, 3, 'curried delegated method worked');

my $e = exception {
	$bleh->splice_nums(1, 0, "foo");
};

like($e, qr/Value "foo" did not pass type constraint/, 'delegated method checked incoming types');
is_deeply($bleh->nums, [3..5], '... and kept the value safe');

my $ref = $bleh->nums;
$bleh->splice_nums(1, 0, '3.111');
is_deeply($bleh->nums, [3, 3, 4, 5], 'delegated coerced value');
my $ref2 = $bleh->nums;
is("$ref", "$ref2", '... without needing to build a new arrayref')
	or do {
		require B::Deparse;
		diag( B::Deparse->new->coderef2text(\&Local::Bleh::splice_nums) );
	};

$bleh = Local::Bleh->new;
@r = $bleh->splice_nums_tap(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method with chaining worked');
is_deeply(\@r, [$bleh], '... and returned correct value');

note 'Local::Bleh2';
{
	package Local::Bleh2;
	use Moo;
	use MooX::TypeTiny;
	use Types::Standard -types;
	use Sub::HandlesVia;

	has nums => (
		is           => 'lazy',
		isa          => ArrayRef->of(Int->plus_coercions(Num, 'int($_)'))->where('1', coercion=>1),
		builder      => sub { [] },
		coerce       => 1,
		handles_via  => 'Array',
		handles      => {
			splice_nums => 'splice',
			first_num   => [ 'get', 0 ],
		},
	);
}

$bleh = Local::Bleh2->new;
$bleh->splice_nums(0, 0, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method worked');
is($bleh->first_num, 3, 'curried delegated method worked');

$e = exception {
	$bleh->splice_nums(1, 0, "foo");
};

like($e, qr/type constraint/, 'delegated method has to do naive type check')
	or do {
		require B::Deparse;
		diag( B::Deparse->new->coderef2text(\&Local::Bleh2::splice_nums) );
	};
is_deeply($bleh->nums, [3..5], '... and kept the value safe');

$ref = $bleh->nums;
$bleh->splice_nums(1, 0, '3.111');
is_deeply($bleh->nums, [3, 3, 4, 5], 'delegated coerced value');
$ref2 = $bleh->nums;
isnt("$ref", "$ref2", '... but sadly needed to build a new arrayref');

done_testing;
