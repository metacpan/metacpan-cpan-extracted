use strict;
use warnings;
use Test::More tests => 11;

use lib 't/lib';
use Helper qw(:LDIFSTORE);

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::Constant;

my $store     = undef;
my $TEST_DN   = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
my $DN_LEVEL2 = 'DC=SnakeOil,DC=com';

ldifstore_check_param_failure('');
ldifstore_check_param_failure('name/of/a/file/that/will/never/ever/exist.ldif');
$store =
  new_ok( 'Net::LDAP::SimpleServer::LDIFStore',
    ['examples/single-entry.ldif'] );

my $list = $store->list();
ok( $list, 'Returns a list' );
is( ref($list), 'ARRAY', 'The list is an array-reference' );

# 3 elements: the one entry and the 2 DNs containing it
is( scalar( @{$list} ), 3, 'the list contains three elements' )
  || diag explain $list;

my $tree = $store->find_tree($TEST_DN);
ok($tree) || diag explain $tree;
is( $tree->{_object}->dn(), $TEST_DN, 'test find_tree' ) || diag explain $tree;

my $entry = $store->find_entry($TEST_DN);
ok($entry) || diag explain $entry;

subtest 'list_with_dn_scope on entry dn' => sub {
    my $list_baseobj = $store->list_with_dn_scope( $TEST_DN, SCOPE_BASEOBJ );
    ok( $list_baseobj, 'returns a list with dn and scope baseobj' )
      || diag 'list baseobj';
    is( scalar( @{$list_baseobj} ), 1, 'list_baseobj contains one element' )
      || diag explain $list_baseobj;
    is( $list_baseobj->[0]->dn(), $TEST_DN );

    my $list_onelevel = $store->list_with_dn_scope( $TEST_DN, SCOPE_ONELEVEL );
    ok( $list_onelevel, 'returns a list with dn and scope onelevel' )
      || diag 'list onelevel';
    is( scalar( @{$list_onelevel} ), 1, 'list_onelevel contains one element' )
      || diag explain $list_onelevel;
    is( $list_baseobj->[0]->dn(), $TEST_DN );

    my $list_subtree = $store->list_with_dn_scope( $TEST_DN, SCOPE_SUBTREE );
    ok( $list_subtree, 'returns a list with dn and scope subtree' )
      || diag 'list subtree';
    is( scalar( @{$list_subtree} ), 1, 'list_subtree contains one element' )
      || diag explain $list_subtree;
    is( $list_baseobj->[0]->dn(), $TEST_DN );
};

subtest 'list_with_dn_scope on second level dn' => sub {
    use Test::Deep qw/cmp_deeply set/;

    my $list_baseobj = $store->list_with_dn_scope( $DN_LEVEL2, SCOPE_BASEOBJ );
    ok( $list_baseobj, 'returns a list with dn and scope baseobj' )
      || diag '2list baseobj';
    is( scalar( @{$list_baseobj} ), 1, 'list_baseobj contains one element' )
      || diag explain $list_baseobj;
    is( $list_baseobj->[0]->dn(), $DN_LEVEL2 );

    my $list_onelevel =
      $store->list_with_dn_scope( $DN_LEVEL2, SCOPE_ONELEVEL );
    ok( $list_onelevel, 'returns a list with dn and scope onelevel' )
      || diag '2list onelevel';
    is( scalar( @{$list_onelevel} ), 2, 'list_onelevel contains two element' )
      || diag explain $list_onelevel;
    cmp_deeply( [ map { $_->dn() } @{$list_onelevel} ],
        set( $DN_LEVEL2, $TEST_DN ) );

    my $list_subtree = $store->list_with_dn_scope( $DN_LEVEL2, SCOPE_SUBTREE );
    ok( $list_subtree, 'returns a list with dn and scope subtree' )
      || diag '2list subtree';
    is( scalar( @{$list_subtree} ), 2, 'list_subtree contains two element' )
      || diag explain $list_subtree;
    cmp_deeply( [ map { $_->dn() } @{$list_onelevel} ],
        set( $DN_LEVEL2, $TEST_DN ) );
};
