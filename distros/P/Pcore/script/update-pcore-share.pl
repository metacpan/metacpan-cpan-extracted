#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Pcore::Util::CA;
use Pcore::Util::URI::Host;

Pcore::Util::CA::update() or exit 3;
Pcore::Util::URI::Host->update_all or exit 3;

1;
__END__
=pod

=encoding utf8

=cut
