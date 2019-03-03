package Module::Lazy::_::test::sample;

use strict;
use warnings;
our $VERSION = 42;

our $alive;

sub new {
    $alive++;
    bless {}, shift;
};

sub DESTROY {
    $alive--;
};

1;
