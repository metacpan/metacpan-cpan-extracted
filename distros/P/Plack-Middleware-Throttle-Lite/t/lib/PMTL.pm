package t::lib::PMTL;

use strict;

sub get_app {
    sub {[
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ]};
}

1; # End of t::lib::PMTL
