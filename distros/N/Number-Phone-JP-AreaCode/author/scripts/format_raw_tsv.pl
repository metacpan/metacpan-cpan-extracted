#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Lingua::JA::Numbers qw/ja2num num2ja/;

my $kanji_num = "一二三四五六七八九〇";

my $input_file  = $ARGV[0];
my $output_file = $ARGV[1];

my $formatted = '';
open my $frh, '<:encoding(utf8)', $input_file;

# Skip Unnecessary Lines
<$frh>;
<$frh>;
<$frh>;
<$frh>;

while (my $line = <$frh>) {
    chomp $line;

    $line =~ s/（ただし、.+）//g;
    $line =~ s/（市外局番を除く.+）//g;
    $line =~ s/並びに/、/g;
    $line =~ s/及び/、/g;
    $line =~ s/､/、/g;
    $line =~ s/｡/。/g;
    $line =~ s/"//g;

    # Add town name before block
    $line =~ s/([\t（、])(\w*?)([$kanji_num][$kanji_num]?丁目、)([$kanji_num][$kanji_num]?丁目)/$1$2$3$2$4/g;

    # Expand blocks (〜から〜まで)
    $line =~ s/([\t（、])(\w*?)([$kanji_num][$kanji_num]?)丁目から([$kanji_num][$kanji_num]?)丁目まで/
        my @blocks = ();
        for my $num (ja2num($3) .. ja2num($4)) {
            push @blocks, $2 . num2ja($num) . '丁目';
        }
        $1 . join '、', @blocks;
    /gex;

    # Expand "東京２３区"
    $line =~ s/東京都２３区/
        my @wards = (qw{足立区 荒川区 板橋区 江戸川区 大田区 葛飾区 北区 江東区 品川区 渋谷区 新宿区 杉並区 墨田区 世田谷区 台東区 中央区 千代田区 豊島区 中野区 練馬区 文京区 港区 目黒区});
        @wards = map { '東京都' . $_ } @wards;
        join '、', @wards;
    /gex;

    if ($line =~ /C?D?E\Z/) {
        $line .= "\n";
    }

    $formatted .= $line;
}
$formatted =~ s/\s*?\Z//;

open my $fwh, '>:encoding(utf8)', $output_file;
print $fwh $formatted;
