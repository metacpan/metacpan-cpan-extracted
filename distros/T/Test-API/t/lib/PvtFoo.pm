package t::lib::PvtFoo;
use strict;
use warnings;

sub _foo { 1 }

sub AUTOLOAD { 1 }

1;
