#!/usr/bin/env perl

package main v0.1.0;

use FindBin;
use lib $FindBin::RealBin;

use Pcore;

sub CLI {
    return { arg => [ script => { isa => 'Str' } ] };
}

1;
__END__
=pod

=encoding utf8

=cut
