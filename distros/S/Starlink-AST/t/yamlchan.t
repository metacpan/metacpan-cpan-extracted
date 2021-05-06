#!perl

use strict;
use Test::More tests => 3;

require_ok('Starlink::AST');

my @data = ();

my $ch = new Starlink::AST::YamlChan(sink => sub {push @data, $_[0];});
isa_ok($ch, 'Starlink::AST::YamlChan');

is($ch->GetC('YamlEncoding'), 'ASDF', 'YamlChan YamlEncoding');
