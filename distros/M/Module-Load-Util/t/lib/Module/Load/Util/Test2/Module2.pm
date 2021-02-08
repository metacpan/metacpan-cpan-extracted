package Module::Load::Util::Test2::Module2;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT    = qw(foo);
our @EXPORT_OK = qw(bar baz foo2 foo3 foo4 foo5 foo6);

sub foo { "foo" }
sub bar { "bar" }
sub baz { "baz" }
sub foo2 { "foo2" }
sub foo3 { "foo3" }
sub foo4 { "foo4" }
sub foo5 { "foo5" }
sub foo6 { "foo6" }

1;
