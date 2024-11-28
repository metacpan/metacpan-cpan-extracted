use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing qw(find_parent_classes);

is dumped(find_parent_classes('Perlmazing')), '("Perlmazing", "Perlmazing::Engine::Exporter", "UNIVERSAL")', 'Perlmazing super classes';
