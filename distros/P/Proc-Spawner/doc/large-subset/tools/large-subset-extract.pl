#!/usr/bin/perl
# Collect shell samples from the corpora into samples.jsonl. large-subset-extract.pl: extract.pl of corpus-run.tar.gz
# with the two tldr rules of 2026-11-02 below.
# Each record: {src, kind (line|script), id, tag, text, loc}. For one-line samples `id` is the snippet ID
# (see PROVENANCE.md); for scripts `loc` = {pre, line0} lets later stages build the ID of a piece:
# "<pre>:<line0 + lines before the piece>[c<column>][-<end line>]".
use strict; use warnings; use JSON::PP; use File::Find;
my $C = shift // '/home/claude/corpora'; my $J = JSON::PP->new->canonical; my %n;
open my $out, '>', shift // 'samples.jsonl' or die $!;
sub put { my %h = @_; return unless $h{text} =~ /\S/; $n{"$h{src}/$h{kind}"}++; print $out $J->encode(\%h), "\n" }
sub slurp { local (@ARGV, $/) = @_; my $s = <>; $s // '' }
sub lineno { my ($s, $off) = @_; 1 + (substr($s, 0, $off) =~ tr/\n//) }

# TL  tldr: `command` lines; {{[-a|--all]}} -> -a, {{text}} -> text. Since 2026-11-02 (doc/large-subset/large-subset-ceiling.md):
# a line of key notation only (<q>, <Ctrl c>, <ArrowLeft>|<ArrowRight>) is not a command: kept, with drop => REASON;
# an argument or pipeline element "..." ("and so on") is dropped from the text, which then keeps the original as orig.
my $KEYS = qr/^\s*(?:<[^<>]+>(?:\s*[|+,]?\s*|\s+))+\s*\z/;
sub tldr_fix { my $t = shift; $t =~ s/\{\{\[([^|\]]*)\|[^\]]*\]\}\}/$1/g; $t =~ s/\{\{(.*?)\}\}/$1/g; $t }
sub tldr_dots { my $t = shift; $t =~ s/\s*\|\s*\.\.\.(?=\s*\|)//g; $t =~ s/(?:\s+|;\s*)\.\.\.(?=[\s;}]|\z)//g; $t }
for my $dir (qw(common linux)) {
  for my $f (sort glob "$C/tldr/pages/$dir/*.md") {
    (my $p = $f) =~ s{.*/pages/}{};
    open my $h, '<', $f or next;
    while (<$h>) { next unless /^`(.+)`\s*$/; my $o = tldr_fix($1); my $t = tldr_dots($o);
      put(src => 'tldr', kind => 'line', id => "TL:$p:$.", text => $t, $t ne $o ? (orig => $o) : (),
          $t =~ $KEYS ? (drop => 'tldr: key notation, not a command') : ()) } } }

# NB  NL2Bash: data/bash/all.cm, one command per line
{ open my $h, '<', "$C/nl2bash/data/bash/all.cm" or die $!;
  while (<$h>) { chomp; put(src => 'nl2bash', kind => 'line', id => "NB:$.", text => $_) } }

# SC  ShellCheck: prop_x = verify[Not][Tree] check "haskell string"
my %hs = (n => "\n", t => "\t", r => "\r", '"' => '"', '\\' => '\\', "'" => "'", '&' => '');
sub hs_unescape { my $t = shift;
  $t =~ s/\\(\d+|x[0-9a-fA-F]+|.)/exists $hs{$1} ? $hs{$1} : $1 =~ m{^x(.+)} ? chr hex $1 : $1 =~ m{^\d+$} ? chr $1 : $1/ge; $t }
find({ no_chdir => 1, wanted => sub {
  return unless /\.hs$/; my $f = $_; (my $p = $f) =~ s{.*/src/ShellCheck/}{};
  open my $h, '<', $f or return;
  while (<$h>) {
    next unless /^\s*(prop_\w+)\s*=\s*(verify(?:Not)?)(?:Tree)?\s+\w+\s+"((?:[^"\\]|\\.)*)"/;
    put(src => 'shellcheck', kind => 'script', id => "SC:$p:$1", tag => $2 eq 'verifyNot' ? 'clean' : 'warned',
        text => hs_unescape($3), loc => { pre => "SC:$p:$1", line0 => 1 }) } } }, "$C/shellcheck/src");

# BC  bash Cookbook examples: every file under chNN/ is a script
find({ no_chdir => 1, wanted => sub {
  return unless -f && m{/ch\d+/}; my $t = slurp($_); return if $t =~ /\0/;
  (my $p = $_) =~ s{.*/bashcookbook-examples/}{};
  put(src => 'cookbook', kind => 'script', id => "BC:$p", text => $t, loc => { pre => "BC:$p", line0 => 1 }) } },
  "$C/bashcookbook-examples");

# PS, PB  pure-sh-bible, pure-bash-bible: fenced code blocks marked sh, shell, bash or nothing
for ([PS => 'pure-sh-bible'], [PB => 'pure-bash-bible']) { my ($pfx, $b) = @$_;
  my $t = slurp("$C/$b/README.md");
  while ($t =~ /^```(\w*)\n(.*?)^```/msg) { my ($lang, $code, $l0) = ($1, $2, lineno($t, $-[2]));
    put(src => $b, kind => 'script', id => "$pfx:README.md:$l0", text => $code, loc => { pre => "$pfx:README.md", line0 => $l0 })
      if $lang =~ /^(?:sh|shell|bash|)$/ } }

# MK  GNU make book (pdftotext -layout): "$ cmd" prompt lines, recipe lines under "target:" lines,
#     and $(shell ...) arguments. Locator: kind:PAGE.LINE (PDF page, line within that page's text).
sub mk_fix {   # make syntax -> plain shell text
  my $t = shift; $t =~ s/^[@+-]+//; $t =~ s/\$\$/\0/g;
  1 while $t =~ s/\$(\((?:[^()]++|(?1))*\)|\{[^{}]*\}|[@<^?*+%])/MAKEVAR/g;
  $t =~ s/\0/\$/g; $t }
{ my @L = split /\n/, slurp("$C/make3.txt"), -1; my ($pg, $ln, @at) = (1, 0);
  for (@L) { if (s/^\f+//) { $pg += length $&; $ln = 0 } push @at, "$pg." . ++$ln }   # page breaks: form feeds
  for my $i (0 .. $#L) {
    $L[$i] =~ /^\s+\$ (\S.*)/ and put(src => 'makebook', kind => 'line', id => "MK:prompt:$at[$i]", text => $1);
    my $k = 0;
    while ($L[$i] =~ /\$\(shell ((?:[^()]++|\((?1)\))*)\)/g) { $k++;
      put(src => 'makebook', kind => 'line', id => "MK:shell:$at[$i]#$k", tag => 'make', text => mk_fix($1)) }
    next unless $L[$i] =~ /^( +)[^\s:=#][^:=]*:(?![:=])/; my $ind = length $1;
    for (my $j = $i + 1; $j <= $#L && $L[$j] =~ /^( +)\S/ && length $1 > $ind; $j++) {
      my $r = $L[$j] =~ s/^\s+//r; my $id = "MK:recipe:$at[$j]";
      next if $r =~ /^(?:endif|endef|else|ifn?eq|ifn?def|define|include|export|override|vpath)\b|^[^\s=]+\s*(?:[:+?!]?=|:)/;
      while ($r =~ /\\$/ && $j < $#L) { $r .= "\n" . ($L[++$j] =~ s/^\s+//r) }
      put(src => 'makebook', kind => 'line', id => $id, tag => 'make', text => mk_fix($r)) } } }
printf STDERR "%-24s %6d\n", $_, $n{$_} for sort keys %n;
