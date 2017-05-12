#!perl
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 15 };
use Net::Shared;
ok(1);
my $listen         = new Net::Shared::Handler;
ok(2);
my $new_shared     = new Net::Shared::Local
                                          (
                                           name=>"new_shared",
                                           accept=>['127.0.0.1']
                                          );
ok(3);
my $old_shared     = new Net::Shared::Local (name=>"old_shared");
ok(4);
my $remote_shared  = new Net::Shared::Remote
                                           (
                                            name=>"remote_shared",
                                            ref=>"new_shared",
                                            port=>$new_shared->port,
                                            address=>'127.0.0.1'
                                           );
ok(5);
$listen->add(\$new_shared, \$old_shared, \$remote_shared);
ok(6);
$listen->store($new_shared, "One ");
ok(7);
$listen->retrieve($new_shared);
ok(8);
$listen->store($old_shared, "two ");
ok(9);
$listen->retrieve($old_shared);
ok(10);
$listen->store($old_shared, [qw(three four)]);
ok(11);
@{$listen->retrieve($old_shared)};
ok(12);
$listen->store($remote_shared, " and five.");
ok(13);
$listen->retrieve($remote_shared);
ok(14);
$listen->destroy_all;
ok(15);
