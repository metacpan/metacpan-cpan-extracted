# -*- perl -*-

# make sure DateTime works
use Test::More tests => 2;

BEGIN { use_ok( 'DateTime',     "Can use DateTime" ) ||
            print "Bail out!\n".
            "Cannot proceed without the DateTime module.\n".
            "Please try installing it via:\n",
            "perl -MCPAN -e 'install DateTime'\n"; }

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$dt = DateTime->new(year      => $year + 1900,
                    month     => $mon + 1,
                    day       => $mday,
                    hour      => $hour,
                    minute    => $min,
                    time_zone => "UTC");

isa_ok ($dt, 'DateTime',         'DateTime object created properly');





