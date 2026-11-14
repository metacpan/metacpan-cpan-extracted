#!/usr/bin/perl
# docs-sync.pl (post-0.11, the user's idea, 2026-11-11): which parts of the documents must be brought in line by hand
# because what they show has changed.  The map, doc/docs-sync.tsv, has one line per part of a document and input it
# draws on (a record, a report, a script), with the input's SHA-256 when the part was last brought in line with it.
# Hashes, not times: Git keeps no file times (a clone gives every file the time of the checkout), CPAN archives do;
# line ends are taken as LF, so a Windows checkout gives the same hashes.
#
# Usage (from the distribution's directory; also make docs-check, make docs-synced DOC=... [PART=...], make docs-map):
#   perl doc/docs-sync.pl check               every part whose inputs changed since, with what to redo; status 1 if any
#   perl doc/docs-sync.pl synced DOC [PART]   after bringing DOC (or only its PART) in line: record the inputs' hashes
#   perl doc/docs-sync.pl map                 the map, by document and part
# A new line: add it to doc/docs-sync.tsv with "-" as its hash (so it counts as not in line), then "synced".
use strict; use warnings; use Digest::SHA qw(sha256_hex);
my $MAP = 'doc/docs-sync.tsv';
my ($cmd, $DOC, $PART) = @ARGV;
defined $cmd && $cmd =~ /^(?:check|synced|map)\z/ && ($cmd ne 'synced' || defined $DOC && length $DOC)
  or die "usage: $0 check | synced DOC [PART] | map\n";
open my $in, '<:utf8', $MAP or die "$MAP: $!";
my (@lines, @rows);   # every line as read (comments kept); the rows, as [doc, part, input, hash, redo, line index]
while (my $l = <$in>) { chomp $l; push @lines, $l; next if $l =~ /^#/ || $l !~ /\S/;
  my @f = split /\t/, $l, -1; @f == 5 or die "$MAP: line $.: not 5 columns (document, part, input, sha256, redo)\n";
  push @rows, [@f, $#lines] }
close $in;
sub hash_of { my $f = shift; open my $h, '<:raw', $f or return 'missing'; local $/; my $t = <$h> // ''; $t =~ s/\r\n/\n/g; sha256_hex($t) }
my %key; my @order;   # document \t part => its rows
for (@rows) { my $k = "$_->[0]\t$_->[1]"; push @order, $k unless $key{$k}; push @{$key{$k}}, $_ }

if ($cmd eq 'map') {
  for my $k (@order) { my ($d, $p) = split /\t/, $k; print "$d, $p\n  redo: $key{$k}[0][4]\n", map("  <- $_->[2]\n", @{$key{$k}}) }
  exit 0 }

if ($cmd eq 'check') { my $n = 0;
  for my $k (@order) { my @ch = grep { hash_of($_->[2]) ne $_->[3] } @{$key{$k}}; next unless @ch; $n++;
    my ($d, $p) = split /\t/, $k;
    print "NOT IN LINE: $d, $p\n",
      map("  changed: $_->[2]" . ($_->[3] eq '-' ? ' (never synced)' : hash_of($_->[2]) eq 'missing' ? ' (missing)' : '') . "\n", @ch),
      "  redo: $key{$k}[0][4]\n  then: make docs-synced DOC=$d PART='$p'\n" }
  my %in = map +($_->[2] => 1), @rows;
  printf "%s: %d parts of %d documents, %d inputs\n", $n ? "$n parts not in line" : 'all in line', scalar(@order),
    scalar(keys %{{ map +($_->[0] => 1), @rows }}), scalar(keys %in);
  exit($n ? 1 : 0) }

# synced
my @mine = grep { $_->[0] eq $DOC && (!defined $PART || !length $PART || $_->[1] eq $PART) } @rows;
@mine or die "$MAP has no line for $DOC" . (defined $PART && length $PART ? ", $PART" : '') . "\n";
for (@mine) { my $h = hash_of($_->[2]); $h eq 'missing' and die "$_->[2]: missing\n";
  $lines[$_->[5]] = join "\t", @$_[0 .. 2], $h, $_->[4] }
open my $o, '>:utf8', "$MAP.new" or die; print $o map "$_\n", @lines; close $o; rename "$MAP.new", $MAP or die;
my %p = map +($_->[1] => 1), @mine; print "in line: $DOC, ", join('; ', sort keys %p), " (", scalar(@mine), " inputs)\n";
