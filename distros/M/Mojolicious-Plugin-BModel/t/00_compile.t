#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use Test::More 0.98 tests => 4;

use_ok( 'Mojolicious::Plugin::BModel' );
use_ok( 'Mojolicious::BModel::Base' );

ok( $Mojolicious::Plugin::BModel::VERSION, 'the version of Mojolicious::Plugin::BModel is set' );
ok( $Mojolicious::BModel::Base::VERSION, 'the version of Mojolicious::BModel::Base is set' );

done_testing();
