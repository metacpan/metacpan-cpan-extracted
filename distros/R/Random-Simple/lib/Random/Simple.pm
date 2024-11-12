package Random::Simple;

our $VERSION = '0.04';
our $debug   = 0;

use strict;
use warnings;

#############################################################

=encoding utf8

=head1 NAME

Random::Simple - Simple, usable, real world random numbers

=head2 Why Random::Simple?

To make generating random numbers as easy as possible and in a manner that
you can use in real code. Generate "good" random numbers without having to
think about it.

=head2 Usage

    use Random::Simple;

    my $integer = random_int($min, $max); # inclusive
    my $bytes   = random_bytes($count);

=head2 See also

=over

=item *
Math::Random::PCG32

=item *
Math::Random::ISAAC

=item *
Math::Random::MT

=item *
Math::Random::Secure

=back

=head2 More information

https://github.com/scottchiefbaker/perl-Random-Simple

=head2 Author

Scott Baker - https://www.perturb.org/

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
		_rand64();
	}
}

# Manually seed the PRNG (no warmup)
sub seed {
	my ($seed1, $seed2) = @_;

	if ($debug) {
		print "SEEDING MANUALLY\n";
	}

	_seed($seed1, $seed2);

	$has_been_seeded = 1;
}

# Randomly seed the PRNG and warmup
sub seed_with_random {
	my ($seed1, $seed2);

	if (-r "/dev/urandom") {
		open(my $FH, "<", "/dev/urandom");
		my $ok = sysread($FH, my $bytes, 16);

		my ($high, $low);

		#my $has_64bit = ($Config{uvsize} == 8);

		# Build the first 64bit seed manually
		# Cannot use Q because it doesn't exist on 32bit Perls
		$high  = unpack("L", substr($bytes, 0, 4));
		$low   = unpack("L", substr($bytes, 4, 4));
		$seed1 = ($high << 32) | $low;

		# Build the second 64bit seed
		$high  = unpack("L", substr($bytes, 8, 4));
		$low   = unpack("L", substr($bytes, 12, 4));
		$seed2 = ($high << 32) | $low;

		close $FH;
	} else {
		# FIXME: Use real entropy this is just a proof of concept
		$seed1 = perl_rand64();
		$seed2 = perl_rand64();
	}

	if ($debug) {
		print "SEEDING RANDOMLY: $seed1 / $seed2\n";
	}

	_seed($seed1, $seed2);

	$has_been_seeded = 1;

	warmup(32);
}

sub perl_rand64 {
	my $high = rand(2**32 - 1);
	my $low  = rand(2**32 - 1);

	my $ret = ($high << 32 | $low);

	return $ret;
}

sub random_bytes {
	my $num = shift();

	if (!$has_been_seeded) { seed_with_random(); }

	my $octets_needed = $num / 4;

	my $ret = "";
	for (my $i = 0; $i < $octets_needed; $i++) {
		my $num = _rand32();

		$ret .= pack("L", $num);
	}

	$ret = substr($ret, 0, $num);

	return $ret;
}

sub random_int {
	my ($min, $max) = @_;

	if (!$has_been_seeded) { seed_with_random(); }

	if ($max < $min) { die("Max can't be less than min"); }

	my $range = $max - $min + 1; # +1 makes it inclusive
	my $ret   = _bounded_rand($range);
	$ret      += $min;

	return $ret;
}

1;
