#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Spec::Functions qw/catfile/;
use Number::Phone::JP::AreaCode::MasterData::TSV2Hash;

use Test::More;

my $tsv_file = catfile($FindBin::Bin, '..', 'master_data', 'area-code-jp.tsv');
my $tsv2hash = Number::Phone::JP::AreaCode::MasterData::TSV2Hash->new;
my $got = $tsv2hash->parse_tsv_file($tsv_file);

is $got->{'北海道'}->{'恵庭市'}->{area_code}, 123;
is $got->{'北海道'}->{'千歳市'}->{area_code}, 123;
is $got->{'北海道'}->{'虻田郡喜茂別町'}->{area_code}, 136;
is $got->{'北海道'}->{'虻田郡真狩村'}->{area_code}, 136;
is $got->{'北海道'}->{'虻田郡洞爺湖町'}->{area_code}, 142;
is $got->{'北海道'}->{'虻田郡豊浦町'}->{area_code}, 142;
is $got->{'北海道'}->{'中川郡幕別町'}->{area_code}, 155;
is $got->{'北海道'}->{'中川郡幕別町忠類朝日'}->{area_code}, 1558;
is $got->{'北海道'}->{'中川郡豊頃町'}->{area_code}, 15;
is $got->{'青森県'}->{'上北郡東北町'}->{area_code}, 175;
is $got->{'青森県'}->{'上北郡野辺地町'}->{area_code}, 175;
is $got->{'青森県'}->{'上北郡横浜町'}->{area_code}, 175;
is $got->{'青森県'}->{'上北郡六ヶ所村'}->{area_code}, 175;
is $got->{'青森県'}->{'上北郡東北町旭北'}->{area_code}, 176;
is $got->{'青森県'}->{'上北郡六戸町'}->{area_code}, 176;
is $got->{'大阪府'}->{'東大阪市加納五丁目'}->{area_code}, 72;
is $got->{'大阪府'}->{'東大阪市加納六丁目'}->{area_code}, 72;
is $got->{'大阪府'}->{'東大阪市加納七丁目'}->{area_code}, 72;
is $got->{'大阪府'}->{'東大阪市加納八丁目'}->{area_code}, 72;
is $got->{'大阪府'}->{'東大阪市岩田町'}->{area_code}, 72;
is $got->{'大阪府'}->{'東大阪市岩田町三丁目'}->{area_code}, 6;
is $got->{'山梨県'}->{'南巨摩郡南部町'}->{area_code}, 556;
is $got->{'新潟県'}->{'新潟市西蒲区打越'}->{area_code}, 25;
is $got->{'新潟県'}->{'新潟市西蒲区'}->{area_code}, 256;
is $got->{'東京都'}->{'町田市'}->{area_code}, 42;
is $got->{'神奈川県'}->{'相模原市緑区小原'}->{area_code}, 42;
is $got->{'東京都'}->{'町田市三輪町'}->{area_code}, 44;
is $got->{'神奈川県'}->{'川崎市'}->{area_code}, 44;
is $got->{'東京都'}->{'足立区'}->{area_code}, 3;
is $got->{'京都府'}->{'京都市'}->{area_code}, 75;
is $got->{'北海道'}->{'二海郡八雲町'}->{area_code}, 137;
is $got->{'北海道'}->{'二海郡八雲町熊石西浜町'}->{area_code}, 1398;
is $got->{'北海道'}->{'苫前郡羽幌町'}->{area_code}, 164;
is $got->{'北海道'}->{'苫前郡羽幌町天売弁天'}->{area_code}, 1648;
is $got->{'東京都'}->{'八王子市'}->{area_code}, 42;
is $got->{'神奈川県'}->{'相模原市緑区与瀬'}->{area_code}, 42;
is $got->{'神奈川県'}->{'相模原市'}->{area_code}, 42;
is $got->{'神奈川県'}->{'相模原市南区磯部'}->{area_code}, 46;
is $got->{'山梨県'}->{'南巨摩郡早川町'}->{area_code}, 556;
is $got->{'三重県'}->{'度会郡玉城町'}->{area_code}, 596;
is $got->{'三重県'}->{'度会郡南伊勢町大江'}->{area_code}, 596;
is $got->{'三重県'}->{'度会郡南伊勢町'}->{area_code}, 599;
is $got->{'千葉県'}->{'千葉市'}->{area_code}, 43;
is $got->{'千葉県'}->{'千葉市花見川区柏井'}->{area_code}, 47;

done_testing;
