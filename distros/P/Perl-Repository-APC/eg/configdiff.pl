#!/usr/bin/perl



=pod

Eigentlich sollte ein Einzeiler reichen, aber er ist schon ein wenig
unuebersichtlich:

diff -U 0 =(/usr/local/perl-5.8.0@17974/bin/perl -V:.\*) =(/usr/local/perl-5.8.0@17975/bin/perl -V:.\*)


=cut

use strict;
use warnings;

die "Usage: $0 perl_1 perl_2" unless @ARGV == 2;
my($l,$r) = @ARGV;

open my $zsh, qq{zsh -c 'diff -U 0 =($l -V:.\\*) =($r -V:.\\*)' |} or die;
while (<$zsh>) {
  next if /^@/;
  next if /^.
          (
           archlib(?:exp)?|
           bin(?:exp)?|
           cf_time|
           config_arg[\dc]+|
           dynamic_ext|
           extensions|
           install.*|
           libs.*|
           man\d.*|
           myuname|
           perlpath|
           prefix.*|
           priv.*|
           scriptdir.*|
           sig_name.*|
           site.*|
           startperl|
           zzzzzzzzzzzzzzz
          )=/x;
  next if /
           =.*\.so\b
          /x;
  print;
}
