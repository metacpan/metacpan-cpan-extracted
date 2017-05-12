use MooseX::Meta::Signature::Positional;
use MooseX::Test::Signature::Positional;
use Test::More;

use strict;
use warnings;

my $tester = MooseX::Test::Signature::Positional->new;

plan tests => $tester->planned;

$tester->test ('MooseX::Meta::Signature::Positional');

