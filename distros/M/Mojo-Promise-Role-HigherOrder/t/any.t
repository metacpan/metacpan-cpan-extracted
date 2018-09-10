use v5.14;
use Mojo::Base -strict;

use feature qw(signatures);
no warnings qw(experimental::signatures);

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::IOLoop;
use Mojo::Promise;

my $class  = 'Mojo::Promise::Role::Any';
my $target = 'Mojo::Promise';
my $method = 'any';

use_ok( $class );

subtest setup => sub {
	can_ok( $class, $method );

	can_ok( $target, 'with_roles' );

	my $promise = $target->with_roles( '+Any' );
	can_ok( $promise, $method );
	};

sub resolve_one ( $number, $position ) {
	my @promises = map {
		Mojo::Promise->new
		} 0 .. $number - 1;

	my $first = Mojo::Promise
		->with_roles('+Any')
		->any( @promises );

	my( @results, @errors );
	$first->then(
		sub { @results = @_ },
		sub { @errors  = @_ }
		);

	$promises[$position]->resolve( qw(Bender Leela) );
	Mojo::IOLoop->one_tick;

	is( scalar @results, 2, 'There are two results' );
	is( scalar @errors,  0, 'There are no errors' );

	is_deeply \@results, [ qw(Bender Leela) ], 'Result is correct';
	}

subtest first  => sub { resolve_one( 20,  0 ) };
subtest last   => sub { resolve_one( 20, 19 ) };
subtest random => sub { resolve_one( 20, int rand 20 ) };

subtest none => sub {
	my @promises = map {
		Mojo::Promise->new
		} 0 .. 5;

	my $first = Mojo::Promise
		->with_roles('+Any')
		->any( @promises );
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

subtest all => sub {
	my @promises = map {
		Mojo::Promise->new
		} 0 .. 5;

	my $first = Mojo::Promise
		->with_roles('+Any')
		->any( @promises );
	isa_ok( $first, $target );

	my( @results, @errors );
	$first->then(
		sub { @results = @_ },
		sub { @errors  = @_ }
		);

	my @characters = qw( Leela Fry Farnsworth Amy Zap Kif );
	$promises[$_]->resolve( $characters[$_] ) foreach 0 .. $#promises;
	Mojo::IOLoop->one_tick;

	is( scalar @results, 1 );
	is( scalar @errors,  0 );

	is( $results[0], 'Leela' );
	};

subtest no_promises => sub {
	my $failed;
	my $first = Mojo::Promise
		->with_roles('+Any')
		->new;
	can_ok( $first, qw(then any) );

	my $any = $first
		->any()
		->then( undef, sub { $failed = 'Good' } );
	Mojo::IOLoop->one_tick;

	is( $failed, 'Good' );
	};

done_testing();
