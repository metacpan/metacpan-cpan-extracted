#!perl -w
use strict;
use Test::More tests => 27;
use lib qw(t/lib);
use Siesta::Test;
use Siesta::List;

my $list = Siesta::List->load('dealers');
isa_ok( $list, "Siesta::List", );
ok( $list, "list created" );

is( $list->name,         "dealers" );
is( $list->owner->email,  'jay@front-of.quick-stop' );

is( $list->post_address, 'dealers@front-of.quick-stop' );
is( $list->return_path,  'dealers-bounce@front-of.quick-stop' );
ok( $list->is_member('jay@front-of.quick-stop'), "jay is a member" );
ok( !( $list->is_member('brodie@comic-store') ), "brodie isn't on any lists" );
ok( !( $list->is_member('dante@quick-stop') ),   "dante isn't on this list" );

# removal
my $old_cnt = scalar( $list->members );
print "# $old_cnt\n";
ok( $list->is_member('bob@front-of.quick-stop'), "unsub - bob is a member" );
ok( $list->remove_member('bob@front-of.quick-stop'), "remove successful" );
is( scalar( $list->members ), $old_cnt - 1, "members count went down" );
ok( !$list->remove_member('dante@quick-stop'), "remove of non-member" );
is( scalar( $list->members ), $old_cnt - 1, "members count unchanged" );
ok( !$list->remove_member('brodie@comic-store'), "remove of a system nobody" );
is( scalar( $list->members ), $old_cnt - 1, "members count unchanged" );
ok( !( $list->is_member('bob@front-of.quick-stop') ),
    "bob no longer a member" );
ok( $list->is_member('jay@front-of.quick-stop'), "jay still is" );

# add
my $count = scalar $list->members;
ok( $list->add_member('bob@front-of.quick-stop'), 'was able to add bob' );
is( scalar $list->members, $count + 1 );
ok( $list->is_member('bob@front-of.quick-stop') );

my $again = Siesta::List->create({
    name   => 'testing',
    owner  => Siesta::Member->create({ email => 'test@chronic.com' }),
});

ok($again);
isa_ok( $again, "Siesta::List" );

$again = Siesta::List->load('testing');
ok( $again, " loaded the testing list ");
is( $again->owner->email, 'test@chronic.com' );
ok( $again->delete, "deleted" );

is( Siesta::List->load('testing'), undef, " and it really went" );
