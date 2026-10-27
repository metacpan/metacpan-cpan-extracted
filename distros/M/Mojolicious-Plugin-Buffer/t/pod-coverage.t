use strict;
use warnings;

use Test::More;

# Author test: every public routine must be documented.  Routines whose
# names start with an underscore are private or protected, and are
# described in comments rather than POD.
eval { require Test::Pod::Coverage; Test::Pod::Coverage->VERSION('1.08'); 1 }
	or plan skip_all => 'Test::Pod::Coverage 1.08 is required to check POD coverage';

# Name lib/ explicitly: by default a stale blib/ would be checked instead
my @modules = Test::Pod::Coverage::all_modules('lib');
plan tests => scalar(@modules);
Test::Pod::Coverage::pod_coverage_ok($_) for @modules;
