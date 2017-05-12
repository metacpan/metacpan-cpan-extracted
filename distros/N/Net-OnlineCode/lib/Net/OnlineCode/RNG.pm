package Net::OnlineCode::RNG;

use strict;
use warnings;

use Fcntl;
use Digest::SHA qw(sha1);
use POSIX qw(ceil floor);

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(random_uuid_160);
$VERSION = '0.04';

#
# Random number generator
#

# A portable random number generator is needed if this program is to
# be used to transfer data from one machine to another. This is
# because the sending program does not transmit any metadata along
# with the check blocks to indicate which and how many composite
# blocks each contains. Likewise, the information relating which and
# how many message blocks are contained in an auxiliary block is not
# sent.
#
# While it would be possible to send this metadata in a particular
# implementation, the solution used here is based on having identical
# pseudo-random number generators set up on both sender and receiver
# machines. When the sender machine begins a transfer, it will send a
# random 160-bit number, along with any other metadata such as
# filename, file size, block size and q and e parameters. Both sender
# and receiver then seed a deterministic PRNG with the 160-bit value.
#
# The sender then uses this seeded PRNG to randomly create 0.55qen
# auxiliary blocks. The receiver carries out the same operation and
# since it is using both the same seed value and the same RNG
# algorithm, both sides should agree on which message blocks are xored
# into which auxiliary blocks.
#
# In a similar manner, when sending a check block, the receiver first
# selects a random seed value. This seed value is then used with the
# RNG algorithm to select which composite blocks are to be included in
# the check block. When the receiver receives the packet it unpacks
# the seed value and uses it to seed the RNG. It goes through the same
# algorithm that the sender used to decide which composite blocks were
# included in the check block and saves that information along with
# the data for the check block itself.
#
# The RNG used in this implementation is based on repeated application
# of the SHA-1 message digest algorithm. This was chosen because:
#
# * SHA-1 is a published standard, so we can be fairly certain that
#   the implementations on different machines will produce the same
#   results.
#
# * there are implementations available in a variety of languages, so
#   it is possible to make interoperable implementations in those
#   languages
#
# * it produces a 160-bit value, which is large enough to use as a
#   unique block (or filename) ID, even if used in a long-running
#   program
#
# * also, we can feed the output of one call to the digest function
#   back in as input to get a new pseudo-random number. It should be
#   highly unlikely that cycles will appear over the lifetime of its
#   use, so it is unlikely to skew the probability distributions that
#   we want to use.
#
# * message digest functions are designed with some desirable features
#   in mind, such as having output bits that are uncorrelated with the
#   input, having long limit cycles and not having obvious biases in
#   the output. These features are very useful when using a message
#   digest algorithm as a PRNG.
#
# The one potential disadvantage of using a message digest algorithm
# over some other custom PRNG is that it may not perform as well.
# However, I believe that the benefits of using a readily-available
# implementation (along with the other advantages listed) outweigh
# this minor disadvantage. For those reasons, I will use SHA-1 here.


# RNG object only contains seed and current values so store them in an
# array rather than a hash for efficiency.

use constant CURRENT => 0;
use constant SEED    => 1;

sub new {

  my ($class, $seed) = @_;
  my $self = [ undef, $seed ];

  bless $self, $class;
  $self->seed($seed);
  return $self;
}

sub new_random {

  my $class = shift;
  my $self = [ undef, undef ];

  bless $self, $class;
  $self->seed_random();
  return $self;
}


# Note that seed/srand with no args is usually implemented to
# pick a random value. For this application, it's better to set
# up some deterministic value

sub seed {
  my $self = shift;
  my $seed = shift;

  die "seed: self object not a reference\n" unless ref($self);

  $seed = "\0" x 20 unless defined($seed);
  $self->[SEED] = $seed;
  $self->[CURRENT] = $seed;
  return $seed;
}

# Also provide seed_random to set a random seed
sub seed_random {
  my $self = shift;

  return $self->seed(random_uuid_160());
}

sub get_seed {
  return  shift->[SEED];
}

# As per Perl's rand, return a float value, 0 <= value < x
sub rand {
  my ($self,$max) = @_;
  $max = $max || 1.0;
  $max += 0.0;			# ensure max is a float

  my ($maxint,$r, $ratio, $current) = (0xffffffff);
  while(1) {
    # advance to the next rand
    $current = $self->[CURRENT] = sha1($self->[CURRENT]);

    # Unpack first 32-bit little-endian word from SHA1 value
    $r = unpack "V1", $current;

    # We calculate the rand by max * uint/(max 32-bit int).
    # Divide first
    if ($r < $maxint) {
      $ratio = $r / $maxint;
      $ratio *= $max;
      return $ratio;
    }
  }
}

# Encapsulate the most common use case of wanting random integers in
# the range [0,max]
sub randint {
  my ($self, $max) = @_;
  return floor($self->rand($max + 1));
}

# The remaining subs are debugging purposes. They report back the
# last random number in a variety of formats, but do not advance
# to the next rand


sub current {
  return shift->[CURRENT];
}

sub as_string {			# alias for "current" method
  return shift->[CURRENT];
}

# Unpacking as bytes or 32-bit unsigned ints. Using little-endian
# since it's more common
sub as_byte_array {
  return unpack "C20", shift->[CURRENT];
}

sub as_uint32_array {
  return unpack "V5", shift->[CURRENT];
}


sub as_hex {
  return unpack "H40", shift->[CURRENT];
}

# *nix-specific helper function to get a random 160-bit value from the
# output of /dev/urandom. This does not affect the current value of
# the RNG, but the returned value can be used to seed it.

sub random_uuid_160 {
  my $self = shift;		# we don't need an object ref.

  # sysopen/sysread avoids any potential problem with opening file in
  # non-binary mode
  if(!sysopen (RAND, "/dev/urandom", O_RDONLY)) {

    # This probably isn't a Linux machine, so fall back to using
    # Perl's internal (non-secure) RNG. This isn't meant to be a
    # proper solution---it's only so that smoker tests don't die on
    # Windows platforms or other *nix distros that have a /dev/random
    # but not a /dev/urandom

    # always warn since this is a potential security problem and not
    # really meant to be used
    warn "This machine doesn't have /dev/urandom; using rand() instead\n";

    my $uuid="";
    for (1..20) { $uuid.= chr CORE::rand 256 };	# rand() is ambiguous
    return $uuid;

  }

  my $bits = '';
  my $chunk = '';
  my $rc = 0;

  # use a loop in case we read fewer than the required number of bytes
  do {
    $rc = (sysread RAND,$chunk,20-length($bits));

    if (defined ($rc)) {
      if ($rc) {
	$bits .= $chunk;
      } else {
	die "Random source dried up (unexpected EOF)!\n";
      }
    } else {
      die "Failed to sysread from urandom: $!\n";
    }
  } while (length $bits < 20);

  return $bits;
}

1;

