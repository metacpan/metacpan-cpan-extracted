#!/usr/bin/perl

use File::Compare;
use Test::Simple tests => 2;

run_perl('Scripts/sh2xml', '-f', '-s', 't/Thai', 't/Thai/text.db', 't/text.xml');
ok(!compare('t/text.xml', 't/text_base.xml', \&line_cmp), 'sh2xml Thai');
run_perl('Scripts/sh2sh', '-s', 't/Thai', 't/Thai/dict.db', 't/dict.xml');
ok(!compare('t/dict.xml', 't/dict_base.xml', \&line_cmp), 'sh2sh Thai');

sub run_perl
{
    my ($prog, @args) = @_;
    
#    local(@ARGV) = @args;
    system('perl', $prog, @args);
}

sub line_cmp
{
    my ($left, $right) = @_;
    $left =~ s/\s*$//o;
    $right =~ s/\s*$//o;
    $left cmp $right;
}