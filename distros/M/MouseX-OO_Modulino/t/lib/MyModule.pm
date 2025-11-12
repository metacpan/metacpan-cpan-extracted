#!/usr/bin/env perl
package MyModule;

use File::AddInc qw($libdir); use lib "$libdir/../../lib";

# use Mouse;
# BEGIN {
#   extends 'MouseX::OO_Modulino';
# }
use MouseX::OO_Modulino -as_base;

has foo => (is => 'ro', default => 'FOO', documentation => 'this is foo');

sub funcA { [shift->foo , "A", @_] }

__PACKAGE__->cli_run(\@ARGV) unless caller;
1;
