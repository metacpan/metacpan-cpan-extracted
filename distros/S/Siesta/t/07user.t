#!perl -w
use strict;
use Test::More tests => 10;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::Member;

my $user = Siesta::Member->load('jay@front-of.quick-stop');
ok( $user, "user created" );
isa_ok( $user, "Siesta::Member" );

is( $user->email, 'jay@front-of.quick-stop');

is_deeply( [ map { $_->name } $user->lists ], ['dealers'], 'lists' );

my $again = Siesta::Member->create( { email    => 'chronic@chronic.com' } );

ok($again);
isa_ok( $again, 'Siesta::Member' );
ok( $again->id, "saving allocated an id" );

$again = Siesta::Member->load('chronic@chronic.com');
is( $again->email, 'chronic@chronic.com' );
ok( $again->delete, "deleted" );

is( Siesta::Member->load('charles@chronic.com'), undef, "and it dorn gorn" );

