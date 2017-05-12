use MooseX::Meta::Signature::Named::Compiled;
use MooseX::Test::Signature::Named;
use Test::More;

use strict;
use warnings;

my $tester = MooseX::Test::Signature::Named->new;

plan tests => $tester->planned;

$tester->test ('MooseX::Meta::Signature::Named::Compiled');

