=pod

=encoding utf-8

=head1 PURPOSE

Test things work with L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

sub does_ok {
	my ($obj, $role) = @_;
	@_ = (
		$obj->DOES($role),
		"Object does role $role",
	);
	goto \&Test::More::ok;
}

{ package Local::Dummy1; use Test::Requires 'Moose' };

{
	package Local::Dummy2;
	use Types::Standard -types;
	use MooX::Press (
		prefix  => 'Local::MyApp',
		factory_package => 'Local::Factories',
		toolkit => 'Moose',
		version => 1.2,
		authority => 'cpan:TOBYINK',
		role => [
			'Livestock',
			'Pet',
			'Milkable' => {
				can => [
					'milk' => sub { 'the white stuff' },
				],
			},
		],
		class => [
			'Animal' => {
				type_name => 'Creature',
				has => [
					'name!'  => Str,
					'colour',
					'age'    => Num,
					'status' => { enum => ['alive', 'dead'], default => 'alive' },
				],
				coerce => [
					Str, 'from_name' => sub {
						my ($class, $name) = @_;
						$class->new(name => $name);
					},
				],
				subclass => [
					'Panda',
					'Cat'  => { with => ['Pet'] },
					'Dog'  => { with => ['Pet'] },
					'Cow'  => { with => ['Livestock', 'Milkable'] },
					'Pig'  => { with => ['Livestock'] },
				],
			},
			'Collar' => {
				has => [ 'animal' => { isa => 'Animal' } ],
			},
		],
	);
};

for my $class (qw/Animal Panda Cat Dog Cow Pig/) {
	my $factory = lc "new_$class";
	can_ok('Local::Factories', $factory);
	my $obj = 'Local::Factories'->$factory(name => "My $class");
	isa_ok($obj, "Moose::Object");
	isa_ok($obj, "Local::MyApp::Animal");
	isa_ok($obj, "Local::MyApp::$class") unless $class eq 'Animal';
	does_ok($obj, 'Local::MyApp::Pet') if $class =~ /Cat|Dog/;
	does_ok($obj, 'Local::MyApp::Livestock') if $class =~ /Cow|Pig/;
	does_ok($obj, 'Local::MyApp::Milkable') if $class =~ /Cow/;
}

is($Local::MyApp::Cow::VERSION, 1.2);
is(Local::MyApp::Cow->VERSION, 1.2);
is($Local::MyApp::Cow::AUTHORITY,'cpan:TOBYINK');
is($Local::MyApp::Types::VERSION, 1.2);
is(Local::MyApp::Types->VERSION, 1.2);
is($Local::MyApp::Types::AUTHORITY,'cpan:TOBYINK');

my $d = Local::MyApp::Cow->new(name => 'Daisy');
is($d->name, 'Daisy', '$d->name');
is($d->status, 'alive', '$d->status');
is($d->milk, 'the white stuff', '$d->milk');

my $e = exception {
	Local::MyApp::Cow->new(age => 1);
};
like($e, qr/required/, 'required attribute');

$e = exception {
	Local::MyApp::Cow->new(name => 1, age => 'Daisy');
};
like($e, qr/type constraint/, 'type constraint');

my $t = Local::MyApp::Types->get_type_for_package(class => 'Local::MyApp::Animal');
is($t->name, 'Creature');
isa_ok($t->coerce('Flo'), 'Local::MyApp::Animal');

is(Local::MyApp::Collar->meta->get_attribute('animal')->type_constraint->name, 'Creature');
is(Local::MyApp::Collar->meta->get_attribute('animal')->type_constraint->class, 'Local::MyApp::Animal');

my $blue = Local::Factories->new_collar(animal => 'Mary');
isa_ok($blue->animal, 'Local::MyApp::Animal');
is($blue->animal->name, 'Mary', '$blue->owner->name');

done_testing;

