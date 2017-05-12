#!perl -w
use Test::More tests => 10;
use strict;
use lib qw(t/lib);
use Siesta::Test 'init_db';
use Siesta::Member;

# named 05 as the plugins need to suck on real data, so this should
# happen first

my $jay = Siesta::Member->create({ email => 'jay@front-of.quick-stop' });
ok( $jay, "added jay" );
is( $jay->email, 'jay@front-of.quick-stop', "Class::DBI basics" );

my $bob = Siesta::Member->create({ email => 'bob@front-of.quick-stop' });
ok( $bob, "added Silent Bob" );

my $dealers = Siesta::List->create({ name => 'dealers',
                                     owner => $jay,
                                     post_address => 'dealers@front-of.quick-stop',
                                     return_path => 'dealers-bounce@front-of.quick-stop',
                                 });
ok( $dealers, "created dealers" );

$dealers = Siesta::List->load('dealers');
is( $dealers->name, 'dealers');
is( $dealers->owner, $jay );

ok( Siesta::Member->create({ email => 'dante@quick-stop' }), "added Dante");
ok( Siesta::Member->create({ email => 'randal@rst-video' }), "added Randal");

ok( $dealers->add_member( $jay ), "added jay to dealers" );
ok( $dealers->add_member( $bob ) );
