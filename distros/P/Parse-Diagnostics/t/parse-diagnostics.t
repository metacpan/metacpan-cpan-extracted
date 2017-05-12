# This is a test for module Parse::Diagnostics.

use warnings;
use strict;
use Test::More;
use Parse::Diagnostics 'parse_diagnostics_pp';

my $text = <<EOF;
croak "Wipe the windows, check the tires, check the oil, a dollar gas";
carp "Too much monkey business";
EOF

my $diagnostics = parse_diagnostics_pp ($text);
cmp_ok (scalar (@$diagnostics), '==', 2);
is ($diagnostics->[0]->{type}, 'croak');
is ($diagnostics->[0]->{line}, 1, "line number");
is ($diagnostics->[1]->{type}, 'carp');
like ($diagnostics->[1]->{message}, qr/monkey business/);
is ($diagnostics->[1]->{line}, 2, "line number");

done_testing ();
# Local variables:
# mode: perl
# End:
