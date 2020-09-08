#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 1;

require_ok('Role::RunAlone') || print "Bail out!\n";

my $version = $Role::RunAlone::VERSION;
diag("Testing Role::RunAlone $version, Perl $], $^X");

exit;

__END__
