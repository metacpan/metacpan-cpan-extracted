use strict;
use v5.6.0;

use Test::More tests => 3;

use School::Code::Compare::Charset;

my $charset = School::Code::Compare::Charset->new()->set_language('txt');

my $visibles = $charset->get_visibles(['x', 'a', 'b', 'z', 'c']) ;
my $ordered  = join '', @{$charset->sort_by_lines($visibles)};

is($ordered, 'abcxz');

my $signes_extracted    = $charset->get_signes(['a;', 'b+', 'c{', 'd}']) ;
my $signes_extracted_s  = $charset->sort_by_lines($signes_extracted);

my $signes_only   = $charset->get_signes([';', '+', '{', '}']) ;
my $signes_only_s = $charset->sort_by_lines([';', '+', '{', '}']) ;

is(join('',@{$signes_extracted_s}), '+;{}');
is(join('',@{$signes_extracted_s}), join('',@{$signes_only_s}));
