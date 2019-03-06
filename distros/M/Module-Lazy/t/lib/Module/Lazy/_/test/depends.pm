package Module::Lazy::_::test::depends;

use strict;
use warnings;
our $VERSION = 3.14;

# NOTE this package name must preceed that of the dependency
# so that they are loaded in reverse order
if (caller) {
    require Module::Lazy::_::test::sample;
    my $throw_away = Module::Lazy::_::test::sample->new;
};

1;
