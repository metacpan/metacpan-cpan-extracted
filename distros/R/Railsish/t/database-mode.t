#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw($Bin);
use File::Spec::Functions;

$ENV{APP_ROOT} = catfile($Bin, "app2");

use Railsish::Database;

{
    my $db = Railsish::Database->new;
    like($db->config->{dsn}, qr/SQLite/);
}

$ENV{RAILSISH_MODE} = "test";

{
    my $db = Railsish::Database->new;
    is($db->config->{dsn}, "hash");
}
