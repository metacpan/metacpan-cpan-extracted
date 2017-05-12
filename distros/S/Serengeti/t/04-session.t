package Serengeti::Session;

use strict;
use warnings;

use Serengeti::Session;

use Test::More qw(no_plan);

my $session = Serengeti::Session->new({ name => "foo"});
isa_ok($session, "Serengeti::Session::Persistent");

1;