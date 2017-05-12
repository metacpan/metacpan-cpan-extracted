#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 1 }

ok (eval { require PAR::Filter::Squish; 1 });

__END__
