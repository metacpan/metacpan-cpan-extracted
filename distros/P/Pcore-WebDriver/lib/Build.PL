#!/usr/bin/env perl

package main v0.1.0;

use FindBin;
use lib $FindBin::RealBin;

use Pcore;
use Pcore::WebDriver;

sub CLI {
    return { arg => [ script => { isa => 'Str' } ] };
}

say 'Updating WebDriver deps ...';

# update deps
Pcore::WebDriver->update_all or exit 3;

1;
__END__
=pod

=encoding utf8

=cut
