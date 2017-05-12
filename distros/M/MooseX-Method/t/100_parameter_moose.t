use MooseX::Meta::Parameter::Moose;
use MooseX::Test::Parameter::Moose;
use Test::More;

use strict;
use warnings;

my $tester = MooseX::Test::Parameter::Moose->new;

plan tests => $tester->planned;

$tester->test ('MooseX::Meta::Parameter::Moose');

