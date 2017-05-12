#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Number::Phone::JP::AreaCode::MasterData::Word2TSV;

use Test::More;

my $obj = Number::Phone::JP::AreaCode::MasterData::Word2TSV->new;
my $text = $obj->to_tsv;

my $i = 0;
for my $row (split /\n/, $text) {
    $i++;
    if ($i == 1) {
        is $row, '＜市外局番の一覧＞';
    }
    elsif ($i == 2) {
        like $row, qr/^（.+年.+月.+日現在）$/;
    }
    elsif ($i == 3) {
        is $row, "番号区画";
    }
    elsif ($i == 4) {
        is $row, "コード\t番号区画\t市外局番\t市内局番";
    }
    else {
        my ($id, $area, $code, $child) = split(/\t/, $row, 4);
        ok $id, "ID exists: line $i";
        ok $area, "Area exists: line $i";
        ok $code, "AreaCode exists: line $i";
        ok $child, "ChildCode exists: line $i";
    }
}

done_testing;
