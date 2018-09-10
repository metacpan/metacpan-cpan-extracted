use v5.14;
use Mojo::Base -strict;

use feature qw(signatures);
no warnings qw(experimental::signatures);

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::IOLoop;
use Mojo::Promise;
use Mojo::Util qw(dumper);

my $class  = 'Mojo::Promise::Role::Some';
my $target = 'Mojo::Promise';
my $method = 'some';
my $role   = '+' . $class =~ s/.*:://r;

use_ok( $class );

sub n_promises ( $n ) { map { Mojo::Promise->new } 1 .. $n }
sub some_p ( $promises, $count ) {
	my $some = Mojo::Promise
		->with_roles($role)
		->$method( $promises, $count );
	isa_ok( $some, $target );
	can_ok( $some, 'then', $method );
	$some;
	}

subtest setup => sub {
	can_ok( $target, 'with_roles' );
	can_ok( $class, $method );

	my $promise = $target->with_roles( $role );
	can_ok( $promise, $method );
	};

subtest no_promises_zero_n => sub {
	my $failed;
	my $some = some_p( [], 0 );

	my $fulfilled;
	$some->then( sub { $fulfilled = 'Leela' } );
	Mojo::IOLoop->one_tick;

	is( $fulfilled, 'Leela' );
	};

subtest no_promises_nonzero_n => sub {
	foreach my $n ( -137 -5, 1, 9, 2.3 ) {
		subtest "n=$n" => sub {
			my $one = some_p( [], $n );
			my $rejected;
			$one->catch( sub { $rejected = 'Farnsworth' } );
			Mojo::IOLoop->one_tick;
			is( $rejected, 'Farnsworth' );
			}
		}
	};

subtest all_reject => sub {
	my $count  = 5;
	my $reject = 1;

	my @promises = n_promises( 5 );

	# Specifying a count that is the same as the number of promises
	# means that a single rejection causes the some to reject.
	my $some = some_p( \@promises, $count - $reject );

	my @errors;
	$some->catch( sub { @errors  = @_ } );

	my @args = qw( Bender Leela );
	$promises[$_]->reject( @args ) for 0 .. $#promises;
	Mojo::IOLoop->one_tick;

	is( scalar @errors,  $reject + 1, 'There are errors' );

	is_deeply( \@errors, [ \@args, \@args ] );
	};

subtest enough_reject => sub {
	my $count   = 5;
	my $fulfill = 3;
	my $reject  = 3; # min to not leave enough to fulfill
	my @promises = n_promises( $count );

	my $some = some_p( \@promises, $fulfill );

	my @errors;
	$some->catch( sub { @errors  = @_ } );


	# reject all of them, but there should only be results up
	# to the earliest count that would make it impossible to get
	# enough to fulfill
	my @args = qw( Amy Zoidberg Fry );
	$promises[$_]->reject( @args ) for 0 .. $#promises;
	Mojo::IOLoop->one_tick;

	is( scalar @errors,  $reject, 'There are many errors' );
	is_deeply( \@errors, [ ( [@args] ) x $reject ] );
	};

subtest more_fulfill => sub {
	my $count   = 9;
	my $fulfill = 5;
	my @promises = n_promises( $count );
	my $some = some_p( \@promises, $fulfill );

	my @results;
	$some->then( sub { @results = @_ } );

	my @args = qw( Hermes Kif );
	$_->resolve( @args ) foreach @promises;
	Mojo::IOLoop->one_tick;

	is( scalar @results, $fulfill, 'There are enough results' );
	is_deeply( \@results, [ ( [@args] ) x $fulfill ] );
	};

subtest n_greater => sub {
	my $count   = 9;
	my @promises = n_promises( $count );
	my $some = some_p( \@promises, $count * 9 );

	my $failed;
	$some->catch( sub { $failed = 'Hermes' } );
	Mojo::IOLoop->one_tick;

	is( $failed, 'Hermes', 'Rejects when N is greater' );
	};

done_testing();
