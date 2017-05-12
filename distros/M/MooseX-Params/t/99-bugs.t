use strict;
use warnings;

use Test::Most;
use MooseX::Params;

sub foo :Args(bar, baz = _build_baz) { $_{baz} }
sub _build_baz { 2 }

lives_ok ( sub { foo(1) }, "parameter builder wrapper with Moose 2.0401" );

done_testing;
