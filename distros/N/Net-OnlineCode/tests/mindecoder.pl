#!/usr/bin/perl

# A minimal decoder test

use lib '../lib';
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;

# Default/command-line arguments
my ($mblocks, $seed, $rng) = ();
while (@ARGV) {
  if ($ARGV[0] eq "-d") {
    shift @ARGV;
    $seed = "\0" x20;
  } elsif ($ARGV[0] eq "-s") {
    shift @ARGV;
    $seed = shift @ARGV;
  } elsif ($ARGV[0] =~ /^\d+/) {
    $mblocks = shift @ARGV;
    last;
  } else {
    die "mindecoder.pl [-d]|[-s seed] [mblocks]\n";
  }
}

$mblocks = $mblocks || 1;
$rng = defined($seed) ?
  Net::OnlineCode::RNG->new($seed) :
  Net::OnlineCode::RNG->new_random;

print "RNG seed: ". $rng->as_hex() . "\n";

my $o=Net::OnlineCode::Decoder->new(mblocks=>$mblocks,initial_rng=>$rng);

my $e = $o->get_e;
my $q =	$o->get_q;
my $coblocks;

print "mblocks = $mblocks\n";
print "ablocks = " . $o->get_ablocks. "\n"; $coblocks = $o->get_coblocks;
print "e = $e\n";
print "q = $q\n";

print "Expected number of check blocks: " .
  int (0.5 + ($mblocks * (1 + $e * $q))) .  "\n";
print "Failure probability: " . (($e/2)**($q + 1)) . "\n";

print "Alt. check block count: " .
  int (0.5 + (1 + $e) * $coblocks) . "\n";

print "1-epsilon/2 times composite = " . ($coblocks * (1-$e/2)) . "\n";

my $done = 0;
my $i = 0;
until ($done) {
  $o->accept_check_block($rng);
  ++$i;
  while (1) {
    ($done,@A) =$o->resolve;
    last unless @A;

    print $i . " ($done): solves " . (join (", ", map { $_->[1]} @A)).  "\n";

    last if $done;
  }
}

