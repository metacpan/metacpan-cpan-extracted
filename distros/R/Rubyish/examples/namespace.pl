#!/usr/bin/env perl
# shelling <shelling@cpan.org>

use lib qw(lib example/lib);
use Rubyish;

use namespace Object => Rubyish::Object;

my $class = Object->new;
print ref($class),"\n";

# this is a example for using Rubyish in short term.


