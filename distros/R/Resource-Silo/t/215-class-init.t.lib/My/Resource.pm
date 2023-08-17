package My::Resource;

use strict;
use warnings;

sub new {
    my ($class, %opt) = @_;
    return bless \%opt, $class;
};

1;
