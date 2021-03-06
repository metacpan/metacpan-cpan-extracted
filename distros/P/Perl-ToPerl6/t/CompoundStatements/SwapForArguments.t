#!perl

use 5.006001;

use strict;
use warnings;
use Test::More tests => 2;

use Test::Perl::ToPerl6::Transformer qw< transform_ok >;

#-----------------------------------------------------------------------------

transform_ok( 'CompoundStatements::SwapForArguments', *DATA );

__DATA__
## name: test
for ( @x ) { }
for $x ( @x ) { }
for my $x ( @x ) { }
##-->
for ( @x ) { }
for ( @x ) -> $x { }
for ( @x ) -> $x { }
