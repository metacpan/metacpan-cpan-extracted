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

use Zydeco::Lite;

BEGIN {
	app 'Local::MyApp'
	=> ( factory_package => 'Local::Factories' )
	=> sub {
		
		toolkit 'Moose';
		version 1.2;
		authority 'cpan:TOBYINK';
		role 'Livestock';
		role 'Pet';
		role 'Milkable' => sub {
			
			method 'milk' => sub {
				return 'the white stuff';
			};
		};
		class 'Animal' => sub {
			
			require Types::Standard;
			
			type_name 'Creature';
			
			has 'name!'   => Types::Standard::Str();
			has 'colour';
			has 'age'     => { type => 'PositiveOrZeroInt' };
			has 'status'  => { enum => ['alive', 'dead'], default => 'alive', is => 'rw' };
			
			coerce 'Str' => 'from_name' => sub {
				my ( $class, $name ) = ( shift, @_ );
				$class->new( name => $name );
			};
			
			class 'Panda';
			class 'Cat'      => sub { with 'Pet' };
			class 'Dog'      => sub { with 'Pet' };
			class 'Cow'      => sub { with 'Livestock', 'Milkable' };
			class 'Pig'      => sub {
				with 'Livestock';
				factory [ 'new_swine', 'new_pig', 'new_sow' ] => \'new';
				factory [ 'new_bacon', 'new_ham', 'new_pork' ] => sub {
					my ( $factory, $class ) = ( shift, shift );
					my $object = $class->new ( @_ );
					$object->status( 'dead' );
					return $object;
				};
				factory 'new_oinker';
			};
		};
		
		class 'Collar' => sub {
			has 'animal' => ( isa => 'Animal' );
		};
	};
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

is($d->FACTORY, 'Local::Factories', '$d->FACTORY');
is($d->FACTORY->type_library, 'Local::MyApp::Types', '$d->FACTORY->type_library');
is($d->FACTORY->get_type_for_package(class => ref $d)->name, 'Cow', '$d->FACTORY->get_type_for_package');

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

my $animal_array_t = Local::MyApp::Types->get_type_for_package(class => '@Local::MyApp::Animal');
is($animal_array_t->display_name, 'ArrayRef[Creature]');

my $xyz;

BEGIN {
	app 'Local::Dummy3' => sub {
		toolkit 'Moose';
		role 'Doubler' => sub {
			around [ 'm1', 'm2' ] => sub {
				my ( $orig, $self, @args ) = (shift, shift, @_);
				return 2 * $self->$orig( @args );
			};
			before 'm1' => sub { ++$xyz };
		};
		role 'Adder' => sub {
			around 'm2' => sub {
				my ( $orig, $self, @args ) = ( shift, shift, @_ );
				return 1 + $self->$orig( @args );
			};
		};
		class 'Base' => sub {
			method 'm1' => sub {  42 };
			method 'm2' => sub { 666 };
			class 'With::Doubler' => sub { with 'Doubler'          };
			class 'With::Adder'   => sub { with 'Adder'            };
			class 'With::Both1'   => sub { with 'Adder', 'Doubler' };
			class 'With::Both2'   => sub { with 'Doubler', 'Adder' };
		};
	};
};

my @expected = (
	[ 'new_base'                => 42, 666 ],
	[ 'new_with_doubler'        => 84, 1332 ],
	[ 'new_with_adder'          => 42, 667 ],
	[ 'new_with_both2'          => 84, 1333 ],
	[ 'new_with_both1'          => 84, 1334 ],
);
for (@expected) {
	my ($factory, $expected_m1, $expected_m2) = @$_;
	my $object = Local::Dummy3->$factory;
	isa_ok($object, 'Local::Dummy3::Base');
	is($object->m1, $expected_m1, "$object\->m1");
	is($object->m2, $expected_m2, "$object\->m1");
}

is($xyz, 3, 'sanity check for before');

done_testing;

