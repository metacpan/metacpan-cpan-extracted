#!/usr/bin/perl
use strict;
use Test::More tests => 12;

BEGIN { use_ok('SVN::ACL'); }
ok($SVN::ACL::VERSION) if $SVN::ACL::VERSION or 1;
ok(my $acl = SVN::ACL->new('./'));
ok($acl->newgroup('bar'));
ok($acl->newuser('foo', 'foo'));
ok($acl->togroup('hcchien', 'bar'));
ok($acl->grant('/acl', 'foo', 'r'));
ok($acl->grant('/acl', 'foo', ''));
ok($acl->grant('/acl','@bar','rw'));
ok($acl->deluser('foo'));
ok($acl->delgroup('bar'));
ok($acl->save);
