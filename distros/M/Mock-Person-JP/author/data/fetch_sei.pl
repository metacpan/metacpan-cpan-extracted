#!/usr/bin/env perl

use strict;
use warnings;
use Encode;
use Lingua::JA::NormalizeText qw/katakana2hiragana/;
use feature qw/say/;

my %data;

open(my $fh, '<', 'name_a10/A10_SEI.TXT') or die $!;
chomp(my @lines = <$fh>);
close($fh);

for my $line (@lines)
{
    my ($yomi, $sei);

    if ($line =~ /^.+,.+,.+$/)
    {
        ($yomi, $sei) = split(/,/, $line);
        $data{"$yomi\t$sei"} = '';
    }
    else { say $line unless $line =~ /DICUT/; }
}

open(my $fh2, '<', 'name_m95/M95_SEI.TXT') or die $!;
chomp(@lines = <$fh2>);
close($fh2);

for my $line (@lines)
{
    my ($yomi, $sei);

    if ($line =~ /^.+\t.+\t.+$/)
    {
        ($yomi, $sei) = split(/\t/, $line);
        $data{"$yomi\t$sei"} = '';
    }
    else { say $line; }
}

open(my $fh3, '<', 'mecab-ipadic-2.7.0-20070801/Noun.name.csv') or die $!;
chomp(@lines = <$fh3>);
close($fh3);

for my $line (@lines)
{
    my ($yomi, $sei, $sei_or_mei);

    if ($line =~ /^.+,.+,.+$/)
    {
        my ($sei, $sei_or_mei, $yomi) = (split(/,/, $line))[0,7,-2];

        if ($sei_or_mei eq '姓' && decode_utf8($sei) !~ /^\p{InKatakana}+$/ && decode_utf8($sei) !~ /^\p{InHiragana}+$/)
        {
            $yomi = encode_utf8 katakana2hiragana(decode_utf8 $yomi);
            $data{"$yomi\t$sei"} = '';
        }
    }
    else { say $line; }
}

for my $key (sort keys %data)
{
    my ($yomi, $sei) = split(/\t/, $key);
    say "$yomi\t$sei";
}
