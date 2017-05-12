package CompileTime;
use strict;
use warnings;

use Package::Stash;

our $foo = 23;

BEGIN {
    my $stash = Package::Stash->new(__PACKAGE__);
    $stash->add_symbol('$bar', $foo);
    $stash->add_symbol('$baz', $stash->get_symbol('$foo'));
}

1;
