use MooseX::Meta::Signature::Combined;
use MooseX::Test::Signature::Combined;
use Test::More;

use strict;
use warnings;

my $tester = MooseX::Test::Signature::Combined->new;

plan tests => $tester->planned;

$tester->test ('MooseX::Meta::Signature::Combined');

