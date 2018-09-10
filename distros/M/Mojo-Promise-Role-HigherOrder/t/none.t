use v5.14;
use Mojo::Base -strict;

use feature qw(signatures);
no warnings qw(experimental::signatures);

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::IOLoop;
use Mojo::Promise;

my $class  = 'Mojo::Promise::Role::None';
my $target = 'Mojo::Promise';
my $method = 'none';
my $role   = '+' . $class =~ s/.*:://r;

use_ok( $class );

subtest setup => sub {
	can_ok( $class, $method );

	can_ok( $target, 'with_roles' );

	my $promise = $target->with_roles( $role );
	can_ok( $promise, $method );
	};

subtest all_reject => sub {
	my @promises = map {
		Mojo::Promise->new
		} 0 .. 5;

	my $first = Mojo::Promise
		->with_roles($role)
		->$method( @promises );
	isa_ok( $first, $target );

	my( @results, @errors );
	$first->then(
		sub { @results = @_ },
		sub { @errors  = @_ }
		);

	$_->reject foreach @promises;
	Mojo::IOLoop->one_tick;

	is( scalar @results, 0, 'There are no results' );
	is( scalar @errors,  0, 'There are no errors' );
	};

subtest one_fulfills => sub {
	my @promises = map {
		Mojo::Promise->new
		} 0 .. 5;

	my $none = Mojo::Promise
		->with_roles($role)
		->$method( @promises );
	isa_ok( $none, $target );

	my( @results, @errors );
	$none->then(
		sub { @results = @_ },
		sub { @errors  = @_ }
		);

	$promises[0]->resolve( 'Bender' );
	Mojo::IOLoop->one_tick;

	is( scalar @results, 0, 'There are no results' );
	is( scalar @errors,  1, 'There is one errors' );

	is( $errors[0], 'Bender', 'There is one errors' );
	};

subtest no_promises => sub {
	my $failed;
	my $none = Mojo::Promise
		->with_roles($role)
		->new;
	can_ok( $none, 'then', $method );

	my $fulfilled;
	$none
		->$method()
		->then( sub { $fulfilled = 'Good' } );
	Mojo::IOLoop->one_tick;

	is( $fulfilled, 'Good' );
	};

done_testing();
