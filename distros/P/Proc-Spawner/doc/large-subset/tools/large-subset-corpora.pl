#!/usr/bin/perl
# large-subset-corpora.pl (post-0.11): fetch the sources of the corpus pools at their pinned commits, as
# doc/test-pools.md, section 1, says (also used by the Makefile's corpus targets: make corpus-help).
# Usage: perl large-subset-corpora.pl CORPORA
# Six Git repositories, a shallow fetch of one commit each, and the book (a PDF, its text by pdftotext -layout).  Needs
# git, curl and pdftotext (poppler-utils), and network access to GitHub.  Restartable: what is there already is kept.
# The book's checksum is checked; its text's checksum depends on the poppler version (that of poppler 24.02.0 is
# printed for comparison).  Writes CORPORA/.done at the end.
use strict; use warnings; use Digest::SHA qw(sha256_hex); use File::Path qw(make_path);
@ARGV == 1 or die "usage: $0 CORPORA\n";
my $C = shift; make_path($C);
my @REPOS = (   # directory, GitHub repository, commit (doc/parsers/shell-subset-test-provenance.md, section 3)
  [tldr => 'tldr-pages/tldr', 'f4566462f5996e13a4f3523f21dc2a863aec53c1'],
  [nl2bash => 'TellinaTool/nl2bash', 'd6b9f5bdff45621d190134e31ab63b7bf7002190'],
  [shellcheck => 'koalaman/shellcheck', '919d37c4d77a7ce16cfc76ebdd781dd6e8081fa5'],
  ['bashcookbook-examples' => 'vossenjp/bashcookbook-examples', '7fc1db649a85eaa5d6c6631397136100763db70f'],
  ['pure-sh-bible' => 'dylanaraps/pure-sh-bible', '26bc7e8d6cfb8716e9ccb97f31c2da80468c5737'],
  ['pure-bash-bible' => 'dylanaraps/pure-bash-bible', '8c19d0b482b04d8d50fb72b4c5148b41ce605c6d']);
my $BOOK = 'https://raw.githubusercontent.com/yjjing/ebooks/master/Managing%20Projects%20with%20GNU%20Make%2C%203rd%20Edition.pdf';
my ($PDFSUM, $TXTSUM) = ('b188a032481ff3b41a84f96b86a3e89b75b63c847e19344dd2edc04220fd88b0',
  '866d44b86ac8fccc510ed31970b30ea7dc780d12e8681017d6d3f8489d6324d6');
sub run { system(@_) == 0 or die "failed: @_\n" }
sub git { my $d = shift; run('git', '-C', $d, @_) }
for (@REPOS) { my ($d, $r, $c) = @$_; my $p = "$C/$d";
  if (-d "$p/.git") { my $h = `git -C $p rev-parse HEAD 2>/dev/null` // ''; chomp $h; next if $h eq $c; }
  else { make_path($p); git($p, 'init', '-q'); git($p, 'remote', 'add', 'origin', "https://github.com/$r") }
  print "$d: $r $c\n"; git($p, 'fetch', '-q', '--depth', '1', 'origin', $c); git($p, 'checkout', '-q', 'FETCH_HEAD');
  my $h = `git -C $p rev-parse HEAD`; chomp $h; $h eq $c or die "$d: at $h, not $c\n" }
my $sum = sub { open my $f, '<:raw', shift or return ''; local $/; sha256_hex(<$f> // '') };
unless (-e "$C/make3.pdf" && $sum->("$C/make3.pdf") eq $PDFSUM) { print "make3.pdf\n"; run('curl', '-sSL', '-o', "$C/make3.pdf", $BOOK) }
$sum->("$C/make3.pdf") eq $PDFSUM or die "make3.pdf: checksum differs from $PDFSUM\n";
run('pdftotext', '-layout', "$C/make3.pdf", "$C/make3.txt") unless -e "$C/make3.txt";
my $t = $sum->("$C/make3.txt");
print "make3.txt: ", $t eq $TXTSUM ? "checksum as with poppler 24.02.0\n" : "checksum $t (poppler 24.02.0 gives $TXTSUM; other versions differ)\n";
open my $o, '>', "$C/.done" or die; print $o "fetched\n"; close $o; print "corpora: $C\n";
