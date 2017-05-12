package Parse::Vipar::Common;

# API:
# use Parse::Vipar::Common;
# $h = SCREENHEIGHT;
# $w = SCREENWIDTH;
# $pw = PANEWIDTH;

use constant SCREENHEIGHT => 600;
use constant SCREENWIDTH => 120;
use constant PANEWIDTH => (SCREENWIDTH/4);

use strict;
no strict 'refs';

@Parse::Vipar::Common::EXPORT = qw(SCREENHEIGHT SCREENWIDTH PANEWIDTH);

sub import {
    my $p = caller(0);
    foreach (@Parse::Vipar::Common::EXPORT) {
        *{"${p}::$_"} = \&{__PACKAGE__."::$_"};
    }
}

1;
