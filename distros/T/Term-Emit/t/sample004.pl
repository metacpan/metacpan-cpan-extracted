#!perl -w
use strict;
use warnings;
use Term::Emit qw/:all/, {-bullets   => ' * ',
                          -color     => 1,
                          -fh        => *STDERR,
                          -closestat => "OK"};

emit "This should have color, bullets, and go to STDERR";
exit 0;
