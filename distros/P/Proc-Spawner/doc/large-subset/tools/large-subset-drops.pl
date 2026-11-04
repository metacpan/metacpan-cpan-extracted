#!/usr/bin/perl
# large-subset-drops.pl (2026-11-02; see doc/large-subset/large-subset-ceiling.md (in Proc-Spawner 0.03)): every sample of samples.jsonl that the
# measurement leaves out, with the reason, as drops.tsv (source, ID, reason). large-subset-remeasure.pl -d drops.tsv
# leaves them out and counts them by reason. Reasons:
#   make book: noisy extraction          the whole source (prose and make syntax in the PDF's text)
#   duplicate of ID                      the same text earlier in the same source
#   tldr: key notation, not a command    set by large-subset-extract.pl
#   shellcheck: scope error SCnnnn       a ShellCheck test string that is wrong where it stands: return, local,
#                                        break or continue outside their function or loop, an exit or return
#                                        status outside 0-255 (by ShellCheck's own codes; shellcheck in PATH)
use strict; use warnings; use JSON::PP; use File::Temp 'tempdir';
my %SCOPE = map +($_ => 1), qw(2104 2105 2106 2151 2152 2168 2242);
my (%first, @sc);
open my $in, '<', shift // 'samples.jsonl' or die; open my $out, '>', shift // 'drops.tsv' or die;
binmode $out, ':utf8';
while (<$in>) { my $h = decode_json $_; my ($src, $id) = @$h{qw(src id)};
  my $why = $src eq 'makebook' ? 'make book: noisy extraction'
    : $first{"$src\0$h->{text}"} ? "duplicate of $first{qq($src\0$h->{text})}" : $h->{drop};
  $first{"$src\0$h->{text}"} //= $id;
  if ($why) { print $out "$src\t$id\t$why\n" } elsif ($src eq 'shellcheck') { push @sc, $h } }
my $d = tempdir(CLEANUP => 1);
for my $i (0 .. $#sc) { open my $f, '>:utf8', "$d/$i.sh" or die; print $f $sc[$i]{text} }
for (my $i = 0; $i < @sc; $i += 400) { my $j = $i + 399 > $#sc ? $#sc : $i + 399;
  open my $p, '-|', 'shellcheck', '-s', 'dash', '-f', 'json1', map "$d/$_.sh", $i .. $j or die;
  my %code; for (@{ decode_json(do { local $/; <$p> })->{comments} }) {
    my ($n) = $_->{file} =~ m{/(\d+)\.sh\z}; $code{$n} //= $_->{code} if $SCOPE{$_->{code}} }
  print $out "shellcheck\t$sc[$_]{id}\tshellcheck: scope error SC$code{$_}\n" for sort { $a <=> $b } keys %code }
