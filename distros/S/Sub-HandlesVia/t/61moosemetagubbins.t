use 5.008001;
use strict;
use warnings;

{ package Local::Dummy1; use Test::Requires 'Moose' };


BEGIN {
	package My::Trait::AutoSetters;

	use Moose::Role;

	around add_attribute => sub {
		my ($orig, $self, $name, @args) = @_;
		my %params = @args == 1 ? %{$args[0]} : @args;

		if (exists $params{writer} && !$params{writer}) {
			delete $params{writer};
			return $self->$orig($name, %params);
		}

		# exit early if it's not something we want or can alter
		return $self->$orig($name, @args)
			if $name =~ /^_/
			|| $name =~ /^\+/;

		$params{writer} //= "set_$name";

		my $attribute = $self->$orig($name, %params);

		return $attribute;
	};
};

{
	package Parent;
	use Moose -traits => [qw(
		My::Trait::AutoSetters
	)];
	use Sub::HandlesVia;
}

{
	package ThisFails;
	use Moose;
	use Sub::HandlesVia;

	extends 'Parent';

	has test => (
		is => 'ro',
		default => sub { [] },
		handles_via => 'Array',
		handles => {
			'add_test' => 'push...'
		}
	);
}

my $t = ThisFails->new;
$t->set_test([3]);
$t->add_test(5)->add_test(6)->add_test(7);

use Test::More;

is_deeply(
	$t->test,
	[ 3, 5, 6, 7 ],
	'yay',
);

done_testing;
