#!perl

use Test::More tests => 4;

BEGIN {
    use_ok('MooseX::Iterator');
    use_ok('MooseX::Iterator::Array');
    use_ok('MooseX::Iterator::Hash');
    use_ok('MooseX::Iterator::Meta::Iterable');
}
