#!perl -T

use strict;
use Test::More tests => 7;
use PostScript::LabelSheet;
use FindBin;

my $eps = "$FindBin::Bin/test1.eps";

my $sheet = new PostScript::LabelSheet
    ->add($eps);

my $label_aref = $sheet->labels();
isa_ok($label_aref, 'ARRAY');
is(scalar(@$label_aref), 1, 'one EPS file added');
is($label_aref->[0]{path}, $eps, '... with path');
is($label_aref->[0]{eps_bb_ll_x}, 0, '... bounding box lower left x');
is($label_aref->[0]{eps_bb_ll_y}, 0, '... lower left y');
is($label_aref->[0]{eps_bb_ur_x}, 122, '... upper right x');
is($label_aref->[0]{eps_bb_ur_y}, 119, '... and upper right y');
