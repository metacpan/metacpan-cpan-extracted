#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 3;
use FindBin qw($Bin);
use Test::XML;

use Template::TAL;

# fake an output layer
package MyOutput;
use base qw( Template::TAL::Output );
sub render { "deadbeef" }

package main;

ok( my $tt = Template::TAL->new(), "got TT object");

ok( $tt->output( MyOutput->new ), "set output layer" );
is( $tt->process(\("<p>honk honk</p>")), "deadbeef", "output layer used");

