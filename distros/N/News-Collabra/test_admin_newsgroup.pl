#!/usr/local/bin/perl -w
use strict;
use News::Collabra;
my $admin = new News::Collabra('user', 'pass');
my $result = $admin->add_newsgroup('junk.test.new','Testing newsgroup','A newsgroup for testing portal and ng interaction');
print $result;
$result = $admin->get_ng_acls('junk.test.new');
print $result;
$result = $admin->add_ng_acl('junk.test.new','nbailey','','manager');
print $result;
$result = $admin->get_properties('junk.test.new');
$result = $admin->set_properties('junk.test.new','Post your tests here!','A test group for FL&T');
print $result;
$result = $admin->remove_newsgroup('junk.test.new');
#$result = $admin->delete_all_articles('myorg.test');
