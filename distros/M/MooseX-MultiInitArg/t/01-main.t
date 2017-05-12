package main;
our @args = qw(foo bar baz);

package WithMeta;
use Moose;
use MooseX::MultiInitArg;

has x => (
	metaclass => 'MultiInitArg',
	is        => 'ro',
	isa       => 'Str',
	init_args => \@main::args,
	required  => 1,
);

package WithTrait;
use Moose;
use MooseX::MultiInitArg;

has x => (
	traits    => ['MooseX::MultiInitArg::Trait'],
	is        => 'ro',
	isa       => 'Str',
	init_args => \@main::args,
	required  => 1,
);

package main;
use Test::More tests => 10;

foreach my $class (qw(WithTrait WithMeta)) {
	my $foo = $class->new(x => 'x');
	is($foo->x, 'x', "$class x works");

	foreach my $arg (@args)
	{
		my $x = $class->new($arg => $arg);
		is($x->x, $arg, "$class $arg works.");
	}

	eval {my $fail = $class->new(x => 'y', foo => 'bar')};
	ok($@, "Supplying more than one arg to $class causes death.");
}

