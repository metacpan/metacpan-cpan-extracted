use strict;
use warnings;
use v5.10;
use utf8;

use Test::More;
use RDF::Lazy;
use RDF::NS;

my $rdf = RDF::Lazy->new;
use constant NS => RDF::NS->new;

my $s = $rdf->literal;
is $s->str, '', 'empty string';
ok !$s->lang && !$s->is('@'), 'no language tag';
is $s->datatype, undef, 'no datatype';

$s = $rdf->literal('নির্বাণ','bn');

is "$s", 'নির্বাণ', 'literal with language tag';
is $s->lang, 'bn', 'language tag';
is $s->datatype, undef, 'datatype';
ok $s->is_bn, 'bn = bn';
ok $s->is_bn_, 'bn ~ bn_';
ok !$s->is_bn_IN, 'bn != bn-IN';
ok !$s->is_en, 'bn != en';

$s = $rdf->literal('Sessel','de-AT');
is $s->str, 'Sessel';
is $s->lang, 'de-at', 'de-at';

ok $s->is('@'), 'has language tag';
ok $s->is_de_AT && $s->is('@de-AT'), 'de-AT = de_AT';
ok $s->is_de_at && $s->is('@de-at'), 'de-AT = de_at';
ok $s->is_de_AT_ && $s->is('@de-AT-'), 'de-AT = de_AT';
ok $s->is_de_  && $s->is('@de-'), 'de-AT ~ de_';
ok !$s->is_de && !$s->is('@de'), 'de-AT != de';

$s = $rdf->literal('1','xsd:int');
is $s->str, '1', 'integer';
ok !$s->lang && !$s->is('@'), 'no language tag';
is $s->datatype->str, NS->xsd_int, 'datatype';
ok $s->datatype('xsd:int'), 'datatype';
ok $s->datatype(NS->xsd_float,NS->xsd_int), 'datatype';

ok !$rdf->literal('true')->datatype, 'plain literal';

done_testing;
