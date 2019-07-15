#!/usr/bin/env perl

package main v0.1.0;

use FindBin;
use lib $FindBin::RealBin;

use Pcore;
use Pcore::Lib::CA;
use Pcore::Lib::Host;

sub CLI {
    return { arg => [ script => { isa => 'Str' } ] };
}

Pcore::Lib::CA::update()     or exit 3;
Pcore::Lib::Host->update_all or exit 3;
P->mime->update              or exit 3;
P->result->update            or exit 3;

1;
__END__
=pod

=encoding utf8

=cut
