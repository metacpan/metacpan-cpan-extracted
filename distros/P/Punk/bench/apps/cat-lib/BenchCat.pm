package BenchCat;

use strict;
use warnings;

# The smallest honest Catalyst application: no plugins, no views, one
# controller. Catalyst wants a real class tree on disk, so this lives
# beside the .psgi files that boot it (cat-hello, cat-dyn, cat-json).

use Catalyst::Runtime 5.80;
use Catalyst;   # no plugins

__PACKAGE__->config(
    name                                        => 'BenchCat',
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 0,
);

__PACKAGE__->setup();

1;
