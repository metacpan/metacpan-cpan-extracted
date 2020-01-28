use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires 'Moose' };

my $var;

{
	package MyApp;
	use MooX::Press (
		toolkit => 'Moose',
		class   => [
			'Class' => {
				has => {
					'attr' => {
						is       => 'lazy',
						trigger  => 1,
						type     => 'Int',
						coerce   => sub { int($_[0]) },
						writer   => 'set_attr',
					},
				},
				can => {
					'_build_attr'   => sub { 7 },
					'_trigger_attr' => sub { $var .= $_[1] },
				},
			},
		],
	);
}

my $obj = MyApp->new_class;

is($obj->attr, 7);

$obj->set_attr(8);
is($obj->attr, 8);

$obj->set_attr(9.1);
is($obj->attr, 9);

is($var, "89");

done_testing;

