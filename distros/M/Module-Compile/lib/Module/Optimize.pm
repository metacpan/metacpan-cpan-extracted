use strict; use warnings;
package Module::Optimize;

use Module::Compile -base;

sub pmc_is_optimizer_module { 1 }

# Compile/Filter some source code into something else. This is almost
# always overridden in a subclass.
sub pmc_optimize {
    my ($class, $source) = @_;
    return $source;
}

1;
