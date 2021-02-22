#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Table::Trans ':all';
my $text =<<EOF;
id: insect
ja: 昆虫
de: Insekten

id: frog
ja: 蛙
de: Froschlurche
EOF
binmode STDOUT, ":encoding(utf8)";
my $trans = read_trans ($text, scalar => 1);
print $trans->{frog}{ja}, "\n";
my %vars;
get_lang_trans ($trans, \%vars, 'ja');
print $vars{trans}{frog}, "\n";
