# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################
use Test::More tests => 9;

# Load the module
use News::Collabra;
ok(1, 'use News::Collabra worked');

# Create an administrator object
my $admin = new News::Collabra('user', 'pass',
			undef, undef, undef);

isa_ok( $admin, 'News::Collabra' );

# Administrate newsgroups
ok( $admin->add_newsgroup('junk.test', 'Testing newsgroup',
	'A newsgroup for testing Collabra.pm'), 'Created junk.test newsgroup' );
ok( $admin->delete_all_articles('junk.test'), 'Purged all articles from junk.test' );
ok( $admin->get_ng_acls('junk.test'), 'Got ACLs for junk.test' );
ok( $admin->add_ng_acl('junk.test','nbailey','','manager'), 'Added ACL to junk.test' );
ok( $admin->get_properties('junk.test'), 'Got properties for junk.test' );
ok( $admin->set_properties('junk.test',
'Post your tests here!','A test group for FL&T'), 'Set properties for junk.test' );
ok( $admin->remove_newsgroup('junk.test'), 'Removed junk.test newsgroup' );

1;
