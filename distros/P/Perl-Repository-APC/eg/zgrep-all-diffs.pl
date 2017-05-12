#!/usr/bin/perl -- -*- mode: cperl -*-


use strict;
use warnings;

use Perl::Repository::APC;
use Compress::Zlib;

use Getopt::Long;
our %Opt;
GetOptions(\%Opt, qw(commitheader!));


my $re = shift or die;
$re =~ s|/|\\/|g;
my $qr = qr/$re/;
my $APC = "APC";

my $apc = Perl::Repository::APC->new($APC);
my @perls = $apc->apcdirs;
# warn "Found ".@perls." directories";
for my $apcdir (@perls) {
  my($apc_branch,$pver,@patches) = @$apcdir;
  # warn $pver;
  for my $p (@patches) {
    my $pp = File::Spec->catfile($APC,$pver,"diffs","$p.gz");
    my $gz = gzopen($pp,"rb");
    while ($gz->gzreadline($_)) {
      last if $Opt{commitheader} && /^Differences \.\.\.$/;
      next unless /$qr/;
      print "$pp: $_";
    }
    $gz->gzclose;
  }
}

