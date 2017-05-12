package MyBuilder;
use strict;
use warnings;
use base 'Module::Build';

sub new {
    if ($^O eq 'MSWin32') {
        warn "This module does not support MSWin32\n";
        exit;
    }
    shift->SUPER::new(@_);
}

1;
