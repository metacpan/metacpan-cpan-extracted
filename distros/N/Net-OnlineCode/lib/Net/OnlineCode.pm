#!/usr/bin/perl

package Net::OnlineCode;

# play nicely as a CPAN module

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);

use constant DEBUG  => 0;
use constant ASSERT => 1;

require Exporter;

@ISA = qw(Exporter);

our @export_xor = qw (xor_strings safe_xor_strings fast_xor_strings);
our @export_default = qw();

%EXPORT_TAGS = ( all => [ @export_default, @export_xor ],
		 xor => [ @export_xor ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = ();
$VERSION = '0.04';

# Use XS for fast xors (TODO: make this optional)
require XSLoader;
XSLoader::load('Net::OnlineCode', $VERSION);

# on to our stuff ...


# Codec parameters
# q    is the number of message blocks that each auxiliary block will
#      link to
# e    epsilon, the degree of "suboptimality". Unlike Reed-Solomon or
#      Rabin's Information Dispersal Algorithm, Online Codes are not
#      optimal. This means that slightly more data needs to be generated
#      than either of these two codes. Also, whereas optimal codes
#      guarantee that a certain fraction of the "check" blocks/digits
#      suffice to reconstruct the original message, online codes only
#      guarantee that it can be reconstructed with a certain
#      probability
#
# Together with the number of blocks, n, these two variables define
# the online code such that (1+qe)n check blocks are sufficient to
# reconstruct the original message with a probability of 1 - (e/2) **
# (q+1).
#

use Carp;
use POSIX qw(ceil floor);
use Digest::SHA qw(sha1 sha1_hex);
use Fcntl;


# Constructor for the base class
#
# This takes the three parameters that define the Online Code scheme,
# corrects the value of epsilon if needed (see below) and then derives
# the following:
#
# * max degree variable (F)
# * number of auxiliary blocks (0.55 *qen)
# * probability distribution p_1, p2, ... , p_F

sub new {

  my $class = shift;
  # The default parameters used here for q and e (epsilon) are as
  # suggested in the paper "Rateless Codes and Big Downloads" by Petar
  # Maymounkov and David Maziere. Note that the value of e may be
  # overridden with a higher value if the lower value doesn't satisfy
  # max_degree(epsilon) > ceil(0.55 * q.e.mblocks)
  my %args = (
	      e           => 0.01,
	      q           => 3,
	      mblocks     => undef,
	      expand_aux  => 0,
	      e_warning   => 0,

	      # We don't use or store any RNG parameter that's been
	      # passed into the constructor.
	      @_
	     );


  my ($q,$e,$mblocks) = @args{qw(q e mblocks)};

  unless (defined $args{mblocks}) {
    carp __PACKAGE__ . ": mblocks => (# message blocks) must be set\n";
    return undef;
  }

  print "Net::OnlineCode mblocks = $mblocks\n" if DEBUG;

  my $P = undef;
  my $e_changed = 0;

  # how many auxiliary blocks would this scheme need?
  my $ablocks =  _count_auxiliary($q,$e,$mblocks);

  # does epsilon value need updating?
  my $f = _max_degree($e);

  if ($f > $mblocks + $ablocks) {

    $e_changed = 1;

    if ($args{e_warning}) {
      print "E CHANGED!!\nWas: $e\n";
      print "Gave F value of $f\n";
    }

    # use a binary search to find a new epsilon such that
    # get_max_degree($epsilon) <= mblocks + ablocks (ie, n)
    my $epsilon = $e;

    local *eval_f = sub {
      my $t = shift;
      return _max_degree(1/(1 + exp(-$t)));
    };

    my $l = -log(1/$e - 1);
    my $r = $l + 1;

    # expand right side of search until we get F <= n'
    while (eval_f($r) > $mblocks + $ablocks) {
      # $r = $l + ($r - $l) * 2;
      $r = 2 * $r - $l;
    }

    # binary search between left and right to find a suitable lower
    # value of epsilon still satisfying F <= n'
    while ($r - $l > 0.01) {
      my $m = ($l + $r) / 2;
      if (eval_f($m) > $mblocks + $ablocks) {
	$l = $m;
      } else {
	$r = $m;
      }
    }

    # update e and ablocks
    $epsilon = 1/(1 + exp(-$r));
    $f       = eval_f($r);
    #$f=_max_degree($epsilon);
    carp __PACKAGE__ . ": increased epsilon value from $e to $epsilon\n"
      if $args{e_warning};
    $e = $epsilon;
    $ablocks =  _count_auxiliary($q,$e,$mblocks);

    if ($args{e_warning}) {

      print "Is now: $e\n";
      print "New F: $f\n";
    }

  }

  # calculate the probability distribution
  print "new: mblocks=$mblocks, ablocks=$ablocks, q=$q\n" if DEBUG;
  $P = _probability_distribution($mblocks + $ablocks,$e);

  die "Wrong number of elements in probability distribution (got "
    . scalar(@$P) . ", expecting $f)\n"
      unless @$P == $f;

  my $self = { q => $q, e => $e, f => $f, P => $P,
	       mblocks => $mblocks, ablocks => $ablocks,
	       coblocks => $mblocks + $ablocks,
               chblocks => 0, expand_aux=> $args{expand_aux},
	       e_changed => $e_changed, unique => {},
	     };

  print "expand_aux => $self->{expand_aux}\n" if DEBUG;

  bless $self, $class;

}

# while it probably doesn't matter too much to the encoder whether the
# supplied e value needed to be changed, if the receiver plugs the
# received value of e into the constructor and it ends up changing,
# there will be a problem with receiving the file.
sub e_changed {
  return shift ->{e_changed};
}

# convenience accessor functions
sub get_mblocks {		# count message blocks; passed into new
  return shift -> {mblocks};
}

sub get_ablocks {		# count auxiliary blocks; set in new
  return shift -> {ablocks};
}

sub get_coblocks {		# count composite blocks
  my $self = shift;
  return $self->{mblocks} + $self->{ablocks};
}

# count checkblocks
sub get_chblocks {
  return shift->{chblocks}
}

sub get_q {			# q == reliability factor
  return shift -> {q};
}

sub get_e {			# e == suboptimality factor
  return shift -> {e};
}

sub get_epsilon {		# epsilon == e, as above
  return shift -> {e};
}

sub get_f {			# f == max (check block) degree
  return shift -> {f};
}

sub get_P {			# P == probability distribution
  return shift -> {P};		# (array ref)
}


# "Private" routines

# calculate how many auxiliary blocks need to be generated for a given
# code setup
sub _count_auxiliary {
  my ($q, $e, $n) = @_;

  my $count = int(ceil(0.55 * $q * $e * $n));
  my $delta = 0.55 * $e;

  warn "failure probability " . ($delta ** $q) . "\n" if DEBUG;
  #$count = int(ceil($q * $delta * $n));

  # Is it better to change q or the number of aux blocks if q is too
  # big? It's certainly easier to keep the q value and increase the
  # number of aux blocks, as I'm doing here, and may even be the right
  # thing to do rather than ignoring the user's q value.
  if ($count < $q) {
    $count = $q;
    # warn "updated _count_auxiliary output value to $q\n";
  }
  return $count;
}

# The max degree specifies the maximum number of blocks to be XORed
# together. This parameter is named F.
sub _max_degree {

  my $epsilon = shift;

  my $quotient = (2 * log ($epsilon / 2)) /
    (log (1 - $epsilon / 2));

  my $delta = 0.55 * $epsilon;
  #$quotient = (log ($epsilon) + log($delta)) / (log (1 - $epsilon));

  return int(ceil($quotient));
}

# Functions relating to probability distribution
#
# From the wikipedia page:
#
# http://en.wikipedia.org/wiki/Online_codes
#
# During the inner coding step the algorithm selects some number of
# composite messages at random and XORs them together to form a check
# block. In order for the algorithm to work correctly, both the number
# of blocks to be XORed together and their distribution over composite
# blocks must follow a particular probability distribution.
#
# Consult the references for the implementation details.
#
# The probability distribution is designed to map a random number in
# the range [0,1) and return a degree i between 1 and F. The
# probability distribution depends on a single input, n, which is the
# number of blocks in the original message. The fixed values for q and
# epsilon are also used.
#
# This code includes two changes from that described in the wikipedia
# page.
#
# 1) Rather than returning an array of individual probabilities p_i,
#    the array includes the cumulative probabilities. For example, if
#    the p_i probabilities were:
#      (0.1, 0.2, 0.3, 0.2, 0.1, 0.1)
#    then the returned array would be:
#      (0.1, 0.3, 0.6, 0.8, 0.9, 1)  (last element always has value 1)
#    This is done simply to make selecting a value based on the random
#    number more efficient, but the underlying probability distribution
#    is the same.
# 2) Handling edge cases. These are:
#    a) the case where n = 1; and
#    b) the case where F > n
#    In both cases, the default value for epsilon cannot be used, so a
#    more suitable value is calculated.
#
# The return value is an array containing:
#
# * the max degree F
# * a possibly updated value of epsilon
# * the F values of the (cumulative) probability distribution

sub _probability_distribution {

  my ($nblocks,$epsilon) = @_;	# nblocks = number of *composite* blocks!

  print "generating probability distribution from nblocks $nblocks, e $epsilon\n"
    if DEBUG;

  my  $f = _max_degree($epsilon);

  # after code reorganisation, this shouldn't happen:
  if ($f > $nblocks) {
    croak "BUG: " .__PACKAGE__ . " - epsilon still too small!\n";
  }

  # probability distribution

  # Calculate the sum of the sequence:
  #
  #                1 + 1/F
  # p_1  =  1  -  ---------
  #                 1 + e
  #
  #
  #             F . (1 - p_1)
  # p_i  =  ---------------------
  #          (F - 1) . (i^2 - i)
  #
  # Since the i term is the only thing that changes for each p_i, I
  # optimise the calculation by keeping a fixed term involving only p
  # and f with a variable one involving i, then dividing as
  # appropriate.

  my $p1     = 1 - (1 + 1/$f)/(1 + $epsilon);
  my $pfterm = (1-$p1) * $f / ($f - 1);

  die "p1 is negative\n" if $p1 < 0;

  # hard-code simple cases where f = 1 or 2
  if ($f == 1) {
    return [1];
  } elsif ($f == 2) {
    return [$p1, 1];
  }

  # calculate sum(p_i) for 2 <= i < F.
  # p_i=F is simply set to 1 to avoid rounding errors in the sum
  my $sum   = $p1;
  my @P     = ($sum);

  my $i = 2;
  while ($i < $f) {
    my $iterm = $i * ($i - 1);
    my $p_i   = $pfterm / $iterm;

    $sum += $p_i;

    die "p_$i is negative\n" if $p_i < 0;

    push @P, $sum;
    $i++;
  }

  if (DEBUG) {
    # Make sure of the assumption that the sum of terms approaches 1.
    # If the "rounding error" below is not a very small number, we
    # know there is a problem with the assumption!
    my $p_last = $sum + $pfterm / ($f * $f - $f);
    my $absdiff = abs (1 - $p_last);
    warn "Absolute difference of 1,sum to p_F = $absdiff\n" if $absdiff >1e-8;
  }

  return [@P,1];
}


# Using Floyd's algorithm instead of Fisher-Yates shuffle. Picks k
# distinct elements from the range [start, start + n - 1]. Avoids the
# need to copy/re-initialise an array of size n every time we make a
# new check block.
sub floyd {
  my ($rng, $start, $n, $k) = @_;
  my %set;
  my ($j, $t) = ($n - $k);
  while ($j < $n) {
    $t = floor($rng->rand($j + 1));
    if (!exists($set{$t + $start})) {
      $set{$t + $start} = undef;
    } else {
      $set{$j + $start} = undef;
    }
    ++$j;
  }
  # die "Floyd didn't pick $k elements" if ASSERT and $k != (keys %set);
  return keys %set;
}

# Routine to calculate the auxiliary block -> message block* mapping.
# The passed rng object must already have been seeded, and both sender
# and receiver should use the same seed.  Returns [[..],[..],..]
# representing which message blocks each of the auxiliary block is
# composed of.

sub auxiliary_mapping {

  my $self = shift;
  my $rng  = shift;

  croak "auxiliary_mapping: rng is not a reference\n" unless ref($rng);

  # hash slices: powerful, but syntax is sometimes confusing
  my ($mblocks,$ablocks,$q) = @{$self}{"mblocks","ablocks","q"};

  my $aux_mapping = [];

  my $ab_string = pack "L*", ($mblocks .. $mblocks + $ablocks -1);

  # list of empty hashes
  my @hashes;
  for (0 .. $mblocks + $ablocks -1) { $hashes[$_] = {}; }

  # Use an unrolled version of Floyd's algorithm for the default case
  # where q=3
  if ($q == 3) {
    my ($a,$b,$c);
    for my $msg (0 .. $mblocks - 1) {
      $a = $mblocks + floor($rng->rand($ablocks - 2));
      $hashes[$a]  ->{$msg}=undef;
      $hashes[$msg]->{$a}  =undef;
      $b = $mblocks + floor($rng->rand($ablocks - 1));
      $b = $mblocks + $ablocks - 2 if $b == $a;
      $hashes[$b]  ->{$msg}=undef;
      $hashes[$msg]->{$b}  =undef;
      $c = $mblocks + floor($rng->rand($ablocks));
      $c = $mblocks + $ablocks - 1 if $c == $a or $c == $b;
      $hashes[$c]  ->{$msg}=undef;
      $hashes[$msg]->{$c}  =undef;
    }
  } else {
    for my $msg (0 .. $mblocks - 1) {
      foreach my $aux (floyd($rng, $mblocks, $ablocks, $q)) {
	$hashes[$aux]->{$msg}=undef;
	$hashes[$msg]->{$aux}=undef;
      }
    }
  }

  # convert list of hashes into a list of lists
  for my $i (0 .. $mblocks + $ablocks -1) {
    print "map $i: " . (join " ", keys %{$hashes[$i]}) . "\n" if DEBUG;
    push @$aux_mapping, [ keys %{$hashes[$i]} ];
  }

  # save and return aux_mapping
  $self->{aux_mapping} = $aux_mapping;
}

# Until I get the auto expand_aux working, this will have to do
sub blklist_to_msglist {

  my ($self,@xor_list) = @_;

  my $mblocks = $self->{mblocks};

  my %blocks;
  while (@xor_list) {
    my $entry = shift(@xor_list);
    if ($entry < $mblocks) { # is it a message block index?
      # toggle entry in the hash
      if (exists($blocks{$entry})) {
	delete $blocks{$entry};
      } else {
	$blocks{$entry}= undef;
      }
    } else {
      # aux block : push all message blocks it's composed of
      my @expansion = @{$self->{aux_mapping}->[$entry]};
      if (DEBUG) {
	print "expand_aux: expanding $entry to " .
	  (join " ", @expansion) . "\n";
      }
      push @xor_list, @expansion;
    }
  }
  return keys %blocks;
}

# Calculate the composition of a single check block based on the
# supplied RNG. Returns a reference to a list of composite blocks
# indices.

sub checkblock_mapping {

  my $self = shift;
  my $rng  = shift;

  croak "rng is not an object reference\n" unless ref($rng);

  my ($mblocks,$coblocks,$P) = @{$self}{"mblocks","coblocks","P"};
  my @coblocks;

  # use weighted distribution to find how many blocks to link
  my $i = 0;
  my $r = $rng->rand;
  ++$i while($r > $P->[$i]);	# terminates since r < P[last]
  ++$i;

  # select i composite blocks uniformly
  @coblocks = floyd($rng, 0, $coblocks , $i);

  if (ASSERT) {
    die "checkblock_mapping: created empty check block\n!" unless @coblocks;
  }

  print "CHECKblock mapping: " . (join " ", @coblocks) . "\n" if DEBUG;

  return \@coblocks;

}

# non-method sub for xoring a source string (passed by reference) with
# one or more target strings. I may reimplement this using XS later to
# make it more efficient, but will keep a pure-perl version with this
# name.
sub safe_xor_strings {

  my $source = shift;

  # die if user forgot to pass in a reference (to allow updating) or
  # called $self->safe_xor_strings by mistake
  croak "xor_strings: arg 1 should be a reference to a SCALAR!\n"
    unless ref($source) eq "SCALAR";

  my $len = length ($$source);

  croak "xor_strings: source string can't have zero length!\n"
    unless $len;

  foreach my $target (@_) {
    croak "xor_strings: targets not all same size as source\n"
      unless length($target) == $len;
    map { substr ($$source, $_, 1) ^= substr ($target, $_, 1) }
      (0 .. $len-1);
  }

  return $$source;
}

# Later, xor_strings could be replaced with an C version with reduced
# error checking, so make a backward-compatible version and an
# explicit fast/unsafe version.
sub xor_strings      { safe_xor_strings(@_) }
#sub fast_xor_strings { safe_xor_strings(@_) } # implemented in OnlineCode.xs.


1;

__END__



=head1 NAME

Net::OnlineCode - A rateless forward error correction scheme

=head1 SYNOPSIS

  use strict;

  # Base class can export routines for doing xor
  use Net::OnlineCode ':xor';

  # Use the constructor to examine what algorithm parameters
  # would be generated for a given number of message blocks

  my $o = Net::OnlineCode->new(
    mblocks => 100_000,  # required parameter
    e => 0.01, q => 3    # optional/default values
  );

  my $e  = $o->get_e;    # The 'e' and 'q' values may be
  my $q  = $o->get_q;    # updated for some values of mblocks
  my $f  = $o->get_f;    # calculated from 'mblocks', 'e' and 'q'

  # At this point, you would normally destroy this object and
  # re-create an Encoder and/or Decoder object using the same
  # parameters as extracted above.

  # some strings to demonstrate use of *_xor_* routines
  my @strings = ("abcde", "     ", "ABCDE", "\0\0\0\0\0");

  # xor routines take a reference to a destination string, which is
  # modified by xoring it with all the other strings passed in. The
  # calculated value is also returned.

  # "safe" xor routine is a pure Perl implementation
  my $result1 = safe_xor_strings(\$strings[0], @strings[1..3]);

  # "fast" xor routine is implemented in C
  my $result2 = fast_xor_strings(\$strings[0], @strings[1..3]);

=head1 DESCRIPTION

This section will not make much sense to you unless you know what Online Codes are and how they work. If this is your first time reading this page, I advise you to skip ahead to the next section.

This module provides a base class for the
L<Net::OnlineCode::Encoder> and L<Net::OnlineCode::Decoder> modules.
It can also be used directly in user code:

=over

=item * to find out what parameters are generated for a given number of message blocks

=item * to access the exported XOR routines

=back

The constructor takes a required 'mblocks' parameter and, optionally,
values for 'e' and 'q' (described below). It then checks whether this
combination of parameters makes sense. If it doesn't, it will change
the 'e' or 'q' values to something more appropriate.

There is usually no need to call the constructor directly since it
will be called during the creation of Net::OnlineCode::Encoder or
Net::OnlineCode::Decoder objects. However, if you wish to examine what
changes were made to the supplied parameters, it is more efficient to
call the base class's constructor directly since it avoids some costly
initialisation code included in the Encoder/Decoder classes.

The remaining two exported functions can be used to XOR pairs of
strings. Since the Online Code scheme is based on XORing blocks of
data, the base class provides two implementations to assist with
this. One implementation (safe_xor_strings) is a slow, pure Perl sub,
while the other (fast_xor_strings) uses a call to a faster C
routine. This module (and the derived Encoder and Decoder module) only
deal with the details necessary to implement the Online Code
algorithms, but do not store or XOR blocks automatically: those tasks
are left for you to implement in whatever way you want.

The remainder of this document will give a brief overview of what
Online Codes are and how they work. For a programmer's view of how to
use this collection of modules, refer to the man pages for the
L<Encoder|Net::OnlineCode::Encoder> and
L<Decoder|Net::OnlineCode::Decoder> modules.

=head1 ONLINE CODES

Briefly, Online Codes are a scheme that allows a sender to break up a
message (eg, a file) into a series of "check blocks" for transmission
over a lossy network. When the receiver has received and decoded
enough check blocks, they will ultimately be able to recover the
original message in its entirety.

Online Codes differ from traditional "forward error correcting"
schemes in two important respects:

=over

=item * they are fast to calculate (on both sending and receiving end); and

=item * they are "rateless", meaning that the sender can send out a (practically) infinite stream of check blocks. The receiver typically only has to correctly receive a certain number of them (usually a only small percentage more than the number of original message blocks) in order to decode the full message.

=back

When using a traditional error-correction scheme, the sender usually
has to set up the encoder parameters to take account of the expected
packet loss rate, and if the loss rate is greater than this, the file
generally cannot be recovered at all. In contrast, with Online Codes,
the sender effectively doesn't care about what the packet loss rate:
it just keeps sending new check blocks until either the receiver(s)
acknowledge the message as having been decoded, or until it has a
reasonable expectation that the message should have been decoded.


=head1 ONLINE CODES IN MORE DETAIL

The fundamental idea used in Online Codes is to xor some number of
message blocks together to form either auxiliary blocks (which are
internal to the algorithm) or check blocks (which are sent across the
network). Each check block is sent along with a block ID, which
encodes information about which message blocks (or auxiliary blocks)
comprise that check block. Initially, the only check blocks that a
receiver can use are those that are comprised of only a single message
block, but as more message blocks are decoded, they can be xored (or,
in algebraic terms, "substituted") into each pending (unsolved) check
block. Eventually, given enough check blocks, the receiver will be
able to solve each of the message blocks.

=head2 ENCODING/DECODING STEPS

Encoding consists of two parts:

=over

=item * Before transmission begins, some number of auxiliary blocks are created by xoring a random selection of message blocks together.

=item * For each check block that is to be transmitted, a random selection of auxiliary and/or message blocks (collectively referred to as "composite blocks") are xored together.

=back

Decoding follows the same steps as in the Encoder, except in
reverse. Each received check block can potentially solve one unknown
auxiliary or message block directly. Further, every time an auxiliary or
message block becomes solved, that value can be "substituted in" to
any check block that has not yet been fully decoded. Those check
blocks may then be able to solve more message or auxiliary blocks.

=head2 PSEUDO-RANDOM NUMBER GENERATORS AND BLOCK IDS

When the receiver receives a check block, it needs to know which
message and/or auxiliary blocks it is composed of. Likewise, it needs
to know which message blocks each auxiliary block is composed of. This
is achieved by having both the sender and receiver side use an
identical pseudo-random number generator algorithm. Since both sides
are using an identical PRNG, they can both use it to randomly select
which message blocks comprise each auxiliary block, and which
composite blocks comprise each check block.

Naturally, for this to work, not only should the sender and receiver
both be using the same PRNG algorithm, but they also need to be using
the same PRNG I<seeds>. This is where I<Block IDs> (and also, during
the Encoder/Decoder construction phase , I<File IDs>) come in. For
check blocks, the sender picks a (truly) random Block ID and uses it
to seed the PRNG. Then, using the PRNG, it pseudo-randomly selects
some number of composite blocks. It then sends the Block ID along with
the xor of all the selected composite blocks. The sender then uses the
Block ID to seed its own PRNG, so when it pseudo-randomly selects the
list of composite blocks, it should be the same as that selected by
the sender.

A similar scheme is used at the start of the transmission to determine
which message blocks are xored to create the auxiliary blocks.

The upshot of this is that Block (and File) IDs only need to be a
fixed size, regardless of how many message blocks there are, how many
composite blocks are included in a check block, and so on. This makes
it much easier to design a packet format and process it at the
sending and receiving sides.

=head1 IMPLEMENTATION DETAILS

The module is a fairly faithful implementation of Maymounkov and
Maziere's paper describing the scheme. There are some slight
variations:

=over

=item * in the case where the epsilon value would produce a max degree (F) value greater than the number of message blocks, it (ie, epsilon) is increased until F <= # of message blocks. The code to do this is based on Python code by Gwylim Ashley.

=item * the graph decoding algorithm also includes an "auxiliary rule", which allows decoding (solving) an auxliary block that comprises only solved message blocks

=item * message blocks are decoded immediately: rather, the calling application makes the choice about when to do the xors (this I<may> be more time-efficient, particularly if the application is storing check blocks to secondary storage, but in any event, decoupling the Online Code algorithm from the XOR step allows much more flexibility)

=back

Apart from that, the original paper does not specify a PRNG algorithm.
This module implements one using SHA-1, since it is portable across
platforms and readily available.


=head1 RELEASE NOTE FOR V0.03

This version of the code is a major advance from the previous
version. Most of the algorithms and API are the same, but this version
is much more optimised, both in terms of speed and memory usage. The
various changes that have been implemented are documented in the
RELEASES file at the top level of distribution tarball.

I consider this version to be stable. While performance has been
improved considerably, it may still be too slow for some applications.
As a result, I intend to re-implement critical parts of it in C for
the next release.

=head1 SEE ALSO

L<Wikipedia page describing Online Codes|http://en.wikipedia.org/wiki/Online_codes>

PDF/PostScript links:

=over

=item * L<"Online Codes": by Petar Maymounkov|http://cs.nyu.edu/web/Research/TechReports/TR2002-833/TR2002-833.pdf>

=item * L<"Rateless Codes and Big Downloads" by Petar Maymounkov and David Maziere|http://pdos.csail.mit.edu/~petar/papers/maymounkov-bigdown-lncs.ps>

=back

L<Github repository for Gwylim Ashley's Online Code implementation|https://github.com/gwylim/online-code> (various parts of my code are based on this)

There are various test/demo programs in the tests directory in this
distribution that can serve as a reference for how to use these
modules. In particular, the following can be useful examples to base
your own code on:

=over

=item * I<mindecoder.pl> is a minimal decoder that doesn't do any XORing of data

=item * I<codec.pl> does both encoding and decoding of a real message string

=item * I<probdist.pl> shows the effects that various message block counts have on the 'e' and 'q' parameters

=back


This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

I am also moving over to using github for all future development:

  https://github.com/declanmalone/gnetraid


=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

The C code at the core of this Perl module can additionally be
redistributed and/or modified under the terms of the "GNU Library
General Public License" ("LGPL"). For the purpose of that license, the
"library" is defined as the unmodified C code in the clib/ directory
of this distribution. You are permitted to change the typedefs and
function prototypes to match the word sizes on your machine, but any
further modification (such as removing the static modifier for
non-exported function or data structure names) are not permitted under
the LGPL, so the library will revert to being covered by the full
version of the GPL.

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

