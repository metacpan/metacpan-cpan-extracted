#! perl

use Test::More tests => 3;

use strict;

BEGIN {
    use_ok("PostScript::PrinterFontMetrics");
}

chdir "t";

my $fontname = "n021024l.pfm";

# Load the metrics info.
my $metrics = eval { new PostScript::PrinterFontMetrics($fontname) };
ok($metrics && !$@, "Metrics: $fontname");

is($metrics->kstringwidth("This costs \244 10. "), 6530, "Width");

