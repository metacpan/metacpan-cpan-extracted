#!/usr/bin/perl

use strict;
use warnings;

# Coder/Decoder test. Encodes/decodes an actual message.

use lib '../lib';
use Net::OnlineCode::Encoder;
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;
use Net::OnlineCode::Bones;
use Digest::SHA qw(sha1);

# export xor helper function names into our namespace
use Net::OnlineCode ':xor';

print "Testing: ENCODER AND DECODER\n";

my ($opt, $blksize, $seed);
while ($ARGV[0] =~ /^-/) {
  $opt = shift @ARGV;
  if ($opt eq "-d") {
    $seed = "00" x 20;
  } elsif ($opt eq "-s") {
    $seed = shift @ARGV
  } else {
    die "codec.pl [-d][-s seed] [block_size]\n";
  }
}

# print aux/check blocks as a hex hash value (debugging only)
sub print_sum {
  my ($data, $size, $before, $after) = @_;
  my $chomped = substr $data, 0, $size;
  my $sum = sha1($chomped);
  print "$before" . unpack("H8", $sum) . "$after";
}


my $blksiz = shift @ARGV || 4;

# test string is 41 characters (a prime, so it needs padding unless
# blocksize is 1 or 41)
my $test = "The quick brown fox jumps over a lazy dog";

# flags to pass to decoder constructor (for testing; usually no need
# to set these as the defaults make most sense)
my $dec_expand_aux = 0;
my $dec_expand_msg = 0;

my $erng;
if (defined($seed)) {
  die "supplied seed must be a hex number (40 characters for SHA1 RNG\n"
    unless length($seed) == 40 and ($seed =~ m/^[0-9a-f]+$/i);

  $erng = Net::OnlineCode::RNG->new(pack "H*", $seed);

} else {

 $erng = Net::OnlineCode::RNG->new_random;

}

my $drng = Net::OnlineCode::RNG->new;
$drng->seed($erng->get_seed);

die "initial seed mismatch\n" unless $erng->get_seed eq $drng->get_seed;
die "initial rng mismatch\n"  unless $erng->as_hex eq $drng->as_hex;

print "SEED: " . $erng->as_hex . "\n";

print "Test string: $test\n";

print "Length: " . length($test) . "\n";
print "Block size: $blksiz\n";

# Common Setup

my $istring  = $test;
my $msg_size = length($test);
my $ostring  = "";

# pad input string up to a multiple of blksiz in length
my $padding = ($blksiz - $msg_size) % $blksiz;
print "Padding length: $padding\n";
$istring .= "x" x $padding;

my $mblocks = length($istring) / $blksiz;

print "Padded string: $istring\n";
print "Message blocks: $mblocks\n";

# Set up encoder, decoder

my $enc = Net::OnlineCode::Encoder
  ->new(mblocks => $mblocks, initial_rng => $erng, expand_aux => 0);

die "Failed to create encoder. Quitting\n" unless ref($enc);

# Ordinarily, we'd create check blocks at this point so that we have
# them available to XOR into the check blocks, but because of the
# expand_aux flag above it means that any references to aux blocks
# will be replaced an expansion in terms of message blocks only

# extract parameters from encoder
my $e = $enc->get_e;
my $q = $enc->get_q;
my $f = $enc->get_f;
my $ablocks  = $enc->get_ablocks;
my $coblocks = $enc->get_coblocks;

print "Auxiliary blocks: $ablocks\n";
print "Encoder parameters:\ne= $e, q = $q, f=$f\n";
print "Expected number of check blocks: " .
  int (0.5 + ($mblocks * (1 + $e * $q))) .  "\n";
print "Failure probability: " . (($e/2)**($q + 1)) . "\n";

print "Setting up decoder with e=$e, q=$q, mblocks=$mblocks\n";

# set up decoder with same parameters
my $dec = Net::OnlineCode::Decoder
  ->new(mblocks => $mblocks, initial_rng => $drng,
	e => $e, q=> $q, expand_aux => $dec_expand_aux,
	expand_msg => $dec_expand_msg);
die "Failed to create decoder. Quitting\n" unless ref($dec);

# Create arrays to store received/decoded message, aux and check blocks
my @decoded_mblocks = (("\0" x $blksiz) x $mblocks);
my @decoded_ablocks = (("\0" x $blksiz) x $ablocks);
my @check_blocks = ();

# Calculate aux blocks and print their "signatures" (8 bytes of sha1)
print "ENCODER: Auxiliary block signatures:\n";
my @encoder_aux_cache = (("\0" x $blksiz) x $ablocks);
my $aux_mapping_arry = $enc->{aux_mapping};
for my $aux_block ($mblocks .. $coblocks - 1) {
  for my $msg (@{$aux_mapping_arry->[$aux_block]}) {
    # print "$aux_block contains $msg\n";
    xor_strings(\($encoder_aux_cache[$aux_block - $mblocks]),
		substr($istring, $blksiz * $msg, $blksiz));
  }
  print_sum($encoder_aux_cache[$aux_block-$mblocks], $blksiz,
	    "  signature $aux_block : ", "\n");
}



print "\nEntering main loop\n";

# main loop
my $check_count = 0;
my $done = 0;
until ($done) {

  # normally, we'd call seed_random, but for testing we want a
  # deterministic order
  my $block_id     = $erng->seed($erng->as_string);

  die "encoder random seed != block_id\n" unless $block_id eq $erng->get_seed;

  print "\nENCODE Block #$check_count " . $erng->as_hex . "\n";

  my $enc_xor_list = $enc->create_check_block($erng);

  print "Encoder check block: " .
    (join ", ", @$enc_xor_list) . "\n";

  # xor check block (just a list of message blocks thanks to
  # expand_aux flag). Note that after removing the check for empty
  # check blocks (those expanding to a null list of messages) in the
  # OnlineCode module, the code below had to be changed to start off
  # with a null string rather than assuming that the message list
  # could be shifted from
  # my $contents = substr($istring, $blksiz * shift @$enc_xor_list, $blksiz);
  my $contents = "\0" x $blksiz;
  foreach (@$enc_xor_list) {
    print "Encoder XORing block $_ into check block $check_count\n";
    if ($_ < $mblocks) {
      xor_strings(\$contents,
		  substr($istring,  $blksiz * $_, $blksiz));
    } else {
      xor_strings(\$contents,
		  $encoder_aux_cache[$_ - $mblocks]);
    }
  }

  if (1 == @$enc_xor_list and $enc_xor_list->[0] < $mblocks) {
    print "SOLITARY ENCODED: $contents\n";
  } else {
    print_sum($contents, $blksiz, "Encoder check block signature: ", "\n");
  }

  # synchronise decoder rng with same seed as encoder
  $drng->seed($block_id);
  print "\nDECODE Block #$check_count " . $drng->as_hex . "\n";


  # save contents of checkblock and add it to the graph
  push @check_blocks, $contents;
  $dec->accept_check_block($drng);

  my @decoded;
  ++$check_count;

  # XOR as many blocks as resolve gives us
  while (1) {
    ($done,@decoded) = $dec->resolve;
    last unless @decoded;


    print "This checkblock solved " . scalar(@decoded) . " composite block(s):\n";
    foreach (@decoded) { print "  " . $_->pp . "\n"; }
    print "This solves the entire message\n" if $done;

    foreach my $decoded_block (@decoded) {

      my $decoded = $decoded_block->[1];

      my @dec_xor_list = $dec->expansion($decoded_block);

      print "\nDecoded block $decoded is composed of: ",
	(join ", ", @dec_xor_list) . "\n";
      die "Decoded message block $decoded had empty XOR list\n"
	unless @dec_xor_list;

      my $block = "\0" x $blksiz;

      # Code below also tests that the expand_aux and expand_msg
      # features are working correctly; we wouldn't normally include
      # these tests.
      foreach my $i (@dec_xor_list) {
	if ($i < $mblocks) {
	  if ($dec_expand_msg) {
	    die "FATAL: codec: got message block $i with expand_msg set\n";
	  }
	  print "DECODER: XORing block $i (message) into $decoded\n";
	  xor_strings(\$block, $decoded_mblocks[$i]);

	} elsif ($i >= $coblocks) { # check block

	  print "DECODER: XORing block $i (check #" .
	    ($i - $coblocks) .
	      ") into $decoded\n";
	  xor_strings(\$block, $check_blocks[$i - $coblocks]);

	} else {			# auxiliary block
	  if ($dec_expand_aux) {
	    die "FATAL: codec: got aux block $i with expand_aux set\n";
	  }
	  print "DECODER: XORing block $i (auxiliary) into $decoded\n";
	  xor_strings(\$block, $decoded_ablocks[$i - $mblocks]);
	}
      }

      # save newly-decoded message/aux block
      if ($decoded < $mblocks) {
	print "Decoded block $decoded (message): '$block'\n";
	$decoded_mblocks[$decoded] = $block;
      } else {
	print "Decoded block $decoded (auxiliary): ";
	print_sum($block, $blksiz, "(signature ", ")\n");
	$decoded_ablocks[$decoded - $mblocks] = $block;
      }
    }
    last if $done;		# escape inner loop
  }
}


print "Decoded text: '" . (join("",@decoded_mblocks)) . "'\n";

