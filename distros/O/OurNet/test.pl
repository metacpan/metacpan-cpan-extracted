# $File: //depot/libOurNet/test.pl $ $Author: autrijus $
# $Revision: #2 $ $Change: 2112 $ $DateTime: 2001/10/17 05:42:55 $
#!/usr/bin/perl -w

use strict;
use constant MODULES => [
    qw/BBS BBSAgent BBSApp::Sync Query Site Template FuzzyIndex ChatBot/
];
use Test::More tests => @{+MODULES} + 1;

use_ok('OurNet');

foreach my $mod (@{+MODULES}) {
    use_ok("OurNet::$mod");
}

__END__
