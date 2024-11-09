package Random::Simple;
BEGIN { our $VERSION = 0.02 }

#############################################################

=encoding utf8

=head1 NAME

Random::Simple - Simple, usable, real world random numbers

=cut

#############################################################

require XSLoader;

XSLoader::load();

use Exporter 'import';
our @EXPORT = qw(random_int random_bytes);

#############################################################

our $DEUBG          = 0;
my $has_been_seeded = 0;

# Throw away the first batch to warm up the PRNG, this is helpful
# if a poor seed (lots of zero bits) was chosen
sub warmup {
	my $iter = $_[0];

	for (my $i = 0; $i < $iter; $i++) {
		rand64();
	}
}

# Manually seed the PRNG (no warmup)
sub seed {
	my ($seed1, $seed2) = @_;

	if ($debug) {
		print "SEEDING MANUALLY\n";
	}

	pcg32_seed($seed1, $seed2);

	$has_been_seeded = 1;
}

# Randomly seed the PRNG and warmup
sub seed_with_random {
	my $seed1, $seed2;

	if (-r "/dev/urandom") {
		open(my $FH, "<", "/dev/urandom");
		my $ok = read($FH, $bytes, 16);

		# Build 2x 64bit unsigned ints from the raw bytes
		$seed1 = unpack("Q", substr($bytes, 0, 8));
		$seed2 = unpack("Q", substr($bytes, 8, 8));

		close $FH;
	} else {
		# FIXME: Use real entropy this is just a proof of concept
		$seed1 = int(rand() * (2**64) -1);
		$seed2 = int(rand() * (2**64) -1);
	}

	if ($DEBUG) {
		print "SEEDING RANDOMLY\n";
	}

	#print("XXX: $seed1, $seed2\n");

	pcg32_seed($seed1, $seed2);

	$has_been_seeded = 1;

	warmup(32);
}

sub random_bytes {
	my $num = shift();

	if (!$has_been_seeded) { seed_with_random(); }

	my $octets_needed = $num / 8;

	my $ret = "";
	for (my $i = 0; $i < $octets_needed; $i++) {
		my $num = rand64();

		$ret .= pack("Q", $num);
	}

	$ret = substr($ret, 0, $num);

	return $ret;
}

sub random_int {
	my ($min, $max) = @_;

	if (!$has_been_seeded) { seed_with_random(); }

	# FIXME: This is modulus and biased... fix later
	my $range  = $max - $min + 1; # +1 makes it inclusive of $min AND $max
	my $num    = rand64();
	my $ret    = $num % $range;
	# Add back the offset
	$ret      += $min;

	return $ret;
}

1;
