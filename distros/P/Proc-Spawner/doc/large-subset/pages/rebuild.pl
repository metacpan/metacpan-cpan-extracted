#!/usr/bin/perl
# rebuild.pl ITEMS PAGE OUT: put new items, groups, lede and Parts list into an already built page (gaps.html).
# The page code is build2.pl's output; this changes only the data. Item format: as build2.pl.
use strict; use warnings; use utf8; use JSON::PP; use FindBin;
binmode STDOUT, ':utf8';
my ($items, $pagef, $out) = @ARGV;
sub slurp { open my $h, '<:utf8', shift or die $!; local $/; <$h> }
my $b2 = slurp("$FindBin::Bin/build2.pl"); my ($subs) = $b2 =~ /(sub esc .*?\n)my \$src = /s or die "subs";
eval $subs; die $@ if $@;
my $src = slurp($items); my (@G, @I, @P);
for my $chunk (split /^(?=%% GROUP |@@ )/m, $src) {
  if ($chunk =~ s/^%% GROUP (\S) (\S+) (.+)\n//) { push @G, { name => $3, intro => md($chunk) }; push @P, { letter => $1, short => $2, name => $3 }; next }
  next unless $chunk =~ s/^@@ (\S+) \| ([^|]+?) \| ([^|]+?) \| (.+)\n//;
  my %it = (id => $1, group => $2, layer => $3, title => inline($4));
  my %f; $f{$1} = $2 while $chunk =~ /^## (\w+)\n(.*?)(?=^## |\z)/msg;
  $it{now} = md($f{now}); $it{plan} = md($f{plan}); $it{nogo} = md($f{nogo}); $it{refs} = inline($f{refs} =~ s/^\s+|\s+$//gr);
  push @I, \%it }
my $J = JSON::PP->new->canonical->indent; my $page = slurp($pagef);
my $g = $J->encode(\@G); my $i = $J->encode(\@I); s/<\//<\\\//g for $g, $i;
$page =~ s{const GROUPS = \[.*?\n\]\n?;\nconst ITEMS = \[.*?\n\s*\]\n?;\n}{const GROUPS = $g;\nconst ITEMS = $i;\n}s or die "no items block";
my $lede = slurp("$items.lede"); $page =~ s{<div class="lede">.*?</div>}{<div class="lede">$lede</div>}s or die "lede";
my $parts = join ',', map qq({letter:"$_->{letter}",short:"$_->{short}",name:"$_->{name}"}), @P;
$page =~ s{buildParts\(\$\("filters"\),\[[^\]]*\]}{buildParts(\$("filters"),[$parts]} or die "parts";
open my $o, '>:utf8', $out or die; print $o $page; printf STDERR "%d groups, %d items\n", scalar @G, scalar @I;
