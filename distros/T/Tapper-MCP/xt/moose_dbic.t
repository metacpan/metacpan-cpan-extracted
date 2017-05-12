#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

ok(1, "deactivated");
exit 0;

use lib "xt";

use Data::Dumper;
use MUser;
use MFoo;

my $user = MUser->new({ hotstuff => "Affe" }); # DBIC takes hashrefs
#diag Dumper($user);
my $foo  = MFoo->new;
$foo->hello($user);

ok(1, "dummy");
