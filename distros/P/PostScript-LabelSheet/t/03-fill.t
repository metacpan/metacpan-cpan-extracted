#!perl -T
use strict;

use Test::More tests => 9;
use PostScript::LabelSheet;

use FindBin;
my $eps1_file = "$FindBin::Bin/test1.eps";
my $eps2_file = "$FindBin::Bin/test2.eps";

my $sheet = new PostScript::LabelSheet;
$sheet
    ->columns(3)
    ->rows(10)
    ->skip(5)
    ->fill_last_page(0)
    ->add($eps1_file);

is(scalar(@{$sheet->labels()}), 1);
is($sheet->count_labels(), 1, 'count labels');
is($sheet->count_labels_per_page(), 30, 'count labels per page');

$sheet->_finalize();
is($sheet->labels()->[-1]{count}, 1);
is($sheet->count_labels(), 1, 'count labels');

$sheet->fill_last_page(1)->_finalize();
is($sheet->labels()->[-1]{count}, 10 * 3 - 5);

$sheet->labels(undef)->add($eps1_file, 35);
is($sheet->count_labels(), 35, 'count labels');
$sheet->_finalize();
is($sheet->labels()->[-1]{count}, 10 * 3 * 2 - 5);

$sheet
    ->labels(undef)
    ->add($eps1_file, 35)
    ->add($eps2_file, 10)
    ->fill_last_page(0)
    ->_finalize();
is($sheet->count_labels(), 45);
