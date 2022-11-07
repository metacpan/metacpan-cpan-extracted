# Before 'make install' is performed this script should be runnable with 'make test'.
# After 'make install' it should work as 'perl Simple-Filter-Macro.t'.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

# Load the Perl pragmas.
use strict;
use warnings;

# Load the required module.
use Test::More tests => 9;

# Define the BEGIN block.
BEGIN { use_ok('Simple::Filter::Macro') };

#########################

# Insert your test code below, the Test::More module is useed here so read
# its man page (perldoc Test::More) for help writing this test script.

# Check if modules can be loaded.
use_ok( 'Simple::Filter::Macro' );
use_ok( 'Simple::Filter::MacroLite' );
use_ok( 'Simple::Filter::SanitiseCompiled' );

# Check if the subroutines are reachable.
use_ok( 'Simple::Filter::SanitiseCompiled', 'SanitiseCompiled' );
use_ok( 'Simple::Filter::SanitiseCompiled', qw(SanitiseCompiled) );

# Check if the subroutines are reachable.
can_ok( 'Simple::Filter::SanitiseCompiled', 'SanitiseCompiled' );

my @subs = qw( SanitiseCompiled );

use_ok( 'Simple::Filter::SanitiseCompiled', @subs );
can_ok( __PACKAGE__, 'SanitiseCompiled' );
