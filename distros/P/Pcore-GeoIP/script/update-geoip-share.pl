#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Pcore::GeoIP;

# update GeoIP
P->geoip->update_all or exit 3;

1;
__END__
=pod

=encoding utf8

=cut
