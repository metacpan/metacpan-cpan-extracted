#!perl -w
use strict;
use warnings;
use Term::Emit qw/:all/, {-bullets => ["* ", "+ ", "- "],
                          -color => 1,
                          -width => 70};

emit "Testing ANSI color escapes for severity levels";

foreach (qw/EMERG ALERT CRIT FAIL FATAL ERROR WARN NOTE INFO OK DEBUG NOTRY UNK/) {
    emit "This  is the $_ severity";
    emit_done($_);
}

emit_done;
exit 0;
