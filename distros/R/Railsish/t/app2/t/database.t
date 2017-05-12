#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;
use FindBin qw($Bin);

use Railsish::Database;

$ENV{APP_ROOT} = "$Bin/..";

my $db = Railsish::Database->new();

use YAML;
diag YAML::Dump($db);

ok($db->can("config"));

