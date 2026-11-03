#!/usr/bin/perl
# Build the checklist page: items.txt (light markup) + the reference page's code -> page.html
use strict; use warnings; use utf8; use JSON::PP;
binmode STDOUT, ':utf8';
my ($items, $ref, $out) = @ARGV;
sub slurp { open my $h, '<:utf8', shift or die $!; local $/; <$h> }
sub esc { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s }
sub inline {   # `code`, ``code with ` inside``, **bold**
  my $s = shift; my $r = "";
  for my $p (split /(``\s?.+?\s?``|`[^`]+`)/s, $s) {
    if ($p =~ /^``\s?(.+?)\s?``$/s or $p =~ /^`([^`]+)`$/) { $r .= "<code>" . esc($1) . "</code>" }
    else { my $t = esc($p); $t =~ s{\*\*(.+?)\*\*}{<b>$1</b>}g; $r .= $t } }
  $r }
sub md {   # paragraphs, - lists, 1. lists, ``` blocks
  my $s = shift; $s =~ s/^\s+|\s+$//g; my @out;
  for my $b (split /\n\s*\n/, $s) {
    if ($b =~ /^```\n(.*)\n```$/s) { push @out, '<pre><code>' . esc($1) . '</code></pre>'; next }
    if ($b =~ /^- /) { push @out, '<ul>' . join('', map '<li>' . inline($_) . '</li>', split /\n- /, $b =~ s/^- //r) . '</ul>'; next }
    if ($b =~ /^\d+\. /) { push @out, '<ol>' . join('', map '<li>' . inline($_) . '</li>', split /\n\d+\. /, $b =~ s/^\d+\. //r) . '</ol>'; next }
    push @out, '<p>' . inline($b) . '</p>' }
  join '', @out }
my $src = slurp($items); my (@G, @I);
# ``` blocks contain blank lines? keep them simple: no blank lines inside
for my $chunk (split /^(?=%% GROUP |@@ )/m, $src) {
  if ($chunk =~ s/^%% GROUP (.+)\n//) { push @G, { name => $1, intro => md($chunk) }; next }
  next unless $chunk =~ s/^@@ (\S+) \| ([^|]+?) \| ([^|]+?) \| (.+)\n//;
  my %it = (id => $1, group => $2, layer => $3, title => inline($4));
  my %f; $f{$1} = $2 while $chunk =~ /^## (\w+)\n(.*?)(?=^## |\z)/msg;
  $it{now} = md($f{now}); $it{plan} = md($f{plan}); $it{nogo} = md($f{nogo}); $it{refs} = inline($f{refs} =~ s/^\s+|\s+$//gr);
  push @I, \%it }
my $J = JSON::PP->new->canonical->indent;
my $page = slurp($ref);
$page =~ s/\A<!doctype html>.*?<body>\n?//s; $page =~ s{</body></html>\s*\z}{};
$page =~ s{<title>.*?</title>}{<title>Shell Large Subset</title>};
$page =~ s{<h1>.*?</h1>}{<h1>Shell Large Subset</h1>};
my $lede = slurp("$items.lede");
$page =~ s{<div class="lede">.*?</div>}{<div class="lede">$lede</div>}s;
my $g = $J->encode(\@G); my $i = $J->encode(\@I); s/<\//<\\\//g for $g, $i;
$page =~ s{const GROUPS = \[.*?\n\];\nconst ITEMS = \[.*?\n\];\n}{const GROUPS = $g;\nconst ITEMS = $i;\n}s or die "no items block";
open my $o, '>:utf8', $out or die; print $o $page;
printf STDERR "%d groups, %d items\n", scalar @G, scalar @I;
