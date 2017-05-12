use strict;
use warnings;

use lib 'lib';
use Physics::Unit::Script::GenPages 'GenNameTable';

my $filename = shift;
open my $fh, ">", $filename or die "Could not open $filename for writing";

# Make sure none of the generated POD commands appear in column 1, to they
# won't be confused with real POD.

print $fh '=head1 NAME

Physics::Unit::UnitsByName

', '=head1 DESCRIPTION

This document lists the units provided by L<Physics::Unit> sorted by name.
Since the POD standard does not do tables, they are formatted as HTML
tables, therefore this is best viewed in a browser-based POD renderer.
Note that the L<physics-unit> script can produce a very similar HTML file
in the location of your choosing should this be more convenient.

', '=head1 UNITS

', '=begin html

';

GenNameTable($fh);

print $fh '
', '=end html

', '=cut
';
