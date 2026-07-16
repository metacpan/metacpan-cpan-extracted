#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use_ok 'Mojolicious::Plugin::Fondation::Authorization';
ok($Mojolicious::Plugin::Fondation::Authorization::VERSION, 'Has VERSION');

done_testing;
