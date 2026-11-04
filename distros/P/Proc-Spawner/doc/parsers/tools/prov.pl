#!/usr/bin/perl
# Restore a test snippet from its snippet ID (see doc/parsers/shell-subset-test-provenance.md), reading the pinned corpora.
#   perl prov.pl CORPORA_DIR ID ...             print each snippet (newlines shown as they are)
#   perl prov.pl CORPORA_DIR --check TESTFILE   restore every ID in a test file and compare with its text
# Independent of extract.pl on purpose: it locates the snippet from the ID alone.
use strict; use warnings;
my $C = shift // die "usage: $0 CORPORA_DIR (ID ... | --check TESTFILE)\n";
my %file;
sub lines_of { my $f = shift; $file{$f} //= do { open my $h, '<', $f or die "$f: $!"; local $/; [ split /\n/, scalar <$h>, -1 ] } }
sub trim { my $t = shift; $t =~ s/^\s+|\s+$//g; $t }
sub span {   # lines L..E of @$L (1-based), the first from column C, the last up to column K
  my ($L, $l, $c, $e, $k) = @_; $e ||= $l; die "line $l out of range\n" if $l < 1 || $e > @$L;
  my @x = @$L[$l - 1 .. $e - 1]; $x[-1] = substr $x[-1], 0, $k if $k; $x[0] = substr $x[0], ($c || 1) - 1; join "\n", @x }
my %hs = (n => "\n", t => "\t", r => "\r", '"' => '"', '\\' => '\\', "'" => "'", '&' => '');
sub hs_unescape { my $t = shift;
  $t =~ s/\\(\d+|x[0-9a-fA-F]+|.)/exists $hs{$1} ? $hs{$1} : $1 =~ m{^x(.+)} ? chr hex $1 : $1 =~ m{^\d+$} ? chr $1 : $1/ge; $t }
sub mk_fix { my $t = shift; $t =~ s/^[@+-]+//; $t =~ s/\$\$/\0/g;
  1 while $t =~ s/\$(\((?:[^()]++|(?1))*\)|\{[^{}]*\}|[@<^?*+%])/MAKEVAR/g; $t =~ s/\0/\$/g; $t }
my @MK;   # make3.txt by page: $MK[page][line] (both 1-based)
sub mk_line { my ($p, $l) = @_;
  unless (@MK) { my ($pg) = (1); $MK[1] = [undef];
    for (@{lines_of("$C/make3.txt")}) { my $x = $_; if ($x =~ s/^\f+//) { $pg += length $&; $MK[$pg] = [undef] } push @{$MK[$pg]}, $x } }
  $MK[$p][$l] // die "MK page $p line $l not found\n" }
my $LOC = qr/(\d+)(?:c(\d+))?(?:-(\d+))?(?:e(\d+))?/;   # line, first column, end line, last column

sub restore { local $_ = shift;
  if (/^TL:(.+):(\d+)$/) { my $x = lines_of("$C/tldr/pages/$1")->[$2 - 1] // die "no line\n";
    $x =~ /^`(.+)`\s*$/ or die "not a command line: $x\n"; my $t = $1;
    $t =~ s/\{\{\[([^|\]]*)\|[^\]]*\]\}\}/$1/g; $t =~ s/\{\{(.*?)\}\}/$1/g; return trim($t) }
  if (/^NB:(\d+)$/) { return trim(lines_of("$C/nl2bash/data/bash/all.cm")->[$1 - 1] // die "no line\n") }
  if (/^SC:(.+?):(prop_\w+):$LOC$/) { my ($f, $p, @l) = ($1, $2, $3, $4, $5, $6);
    my ($src) = grep /^\s*\Q$p\E\s*=/, @{lines_of("$C/shellcheck/src/ShellCheck/$f")} or die "no $p in $f\n";
    $src =~ /=\s*verify(?:Not)?(?:Tree)?\s+\w+\s+"((?:[^"\\]|\\.)*)"/ or die "no string in $p\n";
    return trim(span([ split /\n/, hs_unescape($1), -1 ], @l)) }
  if (/^BC:(.+):$LOC$/) { return trim(span(lines_of("$C/bashcookbook-examples/$1"), $2, $3, $4, $5)) }
  if (/^(PS|PB):README\.md:$LOC$/) { my $d = $1 eq 'PS' ? 'pure-sh-bible' : 'pure-bash-bible';
    return trim(span(lines_of("$C/$d/README.md"), $2, $3, $4, $5)) }
  if (/^MK:prompt:(\d+)\.(\d+)$/) { mk_line($1, $2) =~ /^\s+\$ (\S.*)/ or die "no prompt\n"; return trim($1) }
  if (/^MK:shell:(\d+)\.(\d+)#(\d+)$/) { my ($k, @a) = ($3); my $x = mk_line($1, $2);
    push @a, $1 while $x =~ /\$\(shell ((?:[^()]++|\((?1)\))*)\)/g; return trim(mk_fix($a[$k - 1] // die "no shell #$k\n")) }
  if (/^MK:recipe:(\d+)\.(\d+)$/) { my ($p, $l) = ($1, $2); my $r = mk_line($p, $l) =~ s/^\s+//r;
    while ($r =~ /\\$/) { my $n = $MK[$p][++$l] // do { $p++; $l = 1; mk_line($p, $l) }; $r .= "\n" . ($n =~ s/^\s+//r) }
    return trim(mk_fix($r)) }
  die "unknown ID form\n" }

if (@ARGV && $ARGV[0] eq '--check') {
  open my $h, '<', $ARGV[1] or die $!; my ($n, $bad, $own) = (0, 0, 0);
  while (<$h>) { last if /^__DATA__/ }
  while (<$h>) { chomp; next unless /^(?:ok|rej)\s+\S+\s+(\S+)\s+(.*)$/; my ($id, $t) = ($1, $2);
    if ($id =~ /^OWN:/) { $own++; next }
    $t =~ s/\@N/\n/g; $t =~ s/\@T/\t/g; $t =~ s/\@R/\r/g; $n++;
    my $got = eval { restore($id) } // "ERROR: $@";
    next if $got eq $t; $bad++; print "MISMATCH $id\n  test:     ", $t =~ s/\n/\\n/gr, "\n  restored: ", $got =~ s/\n/\\n/gr, "\n" }
  print "$n corpus snippets checked, $bad mismatches; $own hand-written (OWN) skipped\n"; exit !!$bad }
for (@ARGV) { my $t = eval { restore($_) } // "ERROR: $@"; print "$_\n$t\n\n" }
