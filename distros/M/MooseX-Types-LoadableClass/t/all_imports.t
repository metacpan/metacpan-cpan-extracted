use strict;
use warnings;

use Test::More;

# LoadableClass and ClassName should be exactly the same thing for
# type mappers to get it right when you're switching from one to another.

use MooseX::Types::LoadableClass qw/LoadableClass ClassName LoadableRole/;

foreach my $prefix ('is_', 'to_', '') {
    foreach my $name (qw/LoadableClass ClassName LoadableRole/) {
        my $thing = $prefix . $name;
        ok __PACKAGE__->can($thing), "Exports $thing";
    }
}

done_testing;
