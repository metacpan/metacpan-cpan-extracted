#line 1
package ok;
$ok::VERSION = 0.02;

use strict;
use Test::More ();

sub import {
    shift; goto &Test::More::use_ok if @_;

    # No argument list - croak as if we are prototyped like use_ok()
    my (undef, $file, $line) = caller();
    ($file =~ /^\(eval/) or die "Not enough arguments for 'use ok' at $file line $line\n";
}


__END__

#line 59
