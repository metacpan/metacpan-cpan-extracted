#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   $Set::IntRange::VERSION
# ======================================================================

print "1..1\n";

$n = 1;
if ($Set::IntRange::VERSION eq "5.2")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

