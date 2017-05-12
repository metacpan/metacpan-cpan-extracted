#!/usr/bin/env perl 
use strict;
use warnings;

use Privileges::Drop;

my $user = shift or "die ./drop.pl user";

system("id");
my ($uid, $gid) = drop_privileges($user) or die "Could not drop privileges";
print "Current UID is $uid, GID is $gid\n";
system("id");
if(-f "/proc/$$/status") {
    system("cat /proc/$$/status");
}

