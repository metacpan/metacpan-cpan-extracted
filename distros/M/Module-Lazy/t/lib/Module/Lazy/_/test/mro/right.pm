package Module::Lazy::_::test::mro::right;

use strict;
use warnings;
our $VERSION = 1;

use Module::Lazy 'Module::Lazy::_::test::mro::base';
our @ISA = qw(Module::Lazy::_::test::mro::base);

sub nicate {
    "-new";
};

1;
