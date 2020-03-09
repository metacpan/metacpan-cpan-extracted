
use strict;
use warnings;

use blib;
use Test::More 'no_plan';

my $sMod = 'RDF::Simple::Parser';
use_ok($sMod);

my $o = new $sMod;
isa_ok($o, $sMod);

__END__
