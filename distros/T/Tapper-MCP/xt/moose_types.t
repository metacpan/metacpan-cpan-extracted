#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use lib "xt";

use Data::Dumper;
use BusinessLogic;
use Account;


my $bl  = BusinessLogic->new();

my $act = Account->new( name => "Winfried" );
$bl->hello($act);

ok(1, "dummy");


