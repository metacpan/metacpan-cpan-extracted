package t::Util;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw/run_session/;

use POE;

sub run_session(&) {
    my $code = shift;

    POE::Session->create(
        inline_states => {
            _start => $code,
        },
    );
    POE::Kernel->run;
}

1;

