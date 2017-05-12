use strict;
use warnings;

use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

BEGIN {
    use_ok 'MoopsX::UsingMoose';
}

use lib 't/corpus/lib';

use TestFor::MoopsXUsingMoose;

my $meta = TestFor::MoopsXUsingMoose->meta;

isa_ok $meta, 'Class::MOP::Class::Immutable::Moose::Meta::Class', 'The meta class';

done_testing;
