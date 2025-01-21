package Random::Simple;

use strict;
use warnings;
use Time::HiRes;
use Carp qw(croak);

# https://pause.perl.org/pause/query?ACTION=pause_operating_model#3_5_factors_considering_in_the_indexing_phase
our $VERSION = '0.18';
our $debug   = 0;

#############################################################

require XSLoader;

XSLoader::load();

use Exporter 'import';
our @EXPORT = qw(random_int random_bytes random_float random_elem rand srand);

#############################################################

my $has_been_seeded = 0;

# Throw away the first batch to warm up the PRNG, this is helpful
# if a poor seed (lots of zero bits) was chosen
sub warmup {
	my $iter = $_[0];

	for (my $i = 0; $i < $iter; $i++) {
		Random::Simple::_rand64(); # C API
	}
}

# Manually seed the PRNG (no warmup)
sub seed {
	my ($seed1, $seed2) = @_;

	if ($debug) {
		print "SEEDING MANUALLY ($seed1, $seed2)\n";
	}

	Random::Simple::_seed($seed1, $seed2); # C API

	$has_been_seeded = 1;
}

# Fetch random bytes from the OS supplied method
# /dev/urandom = Linux, Unix, FreeBSD, Mac, Android
# Windows requires the Win32::API call to call CryptGenRandom()
sub os_random_bytes {
	my $count  = shift();
	my $ret    = "";

	if ($^O eq 'MSWin32') {
		require Win32::API;

		my $rand = Win32::API->new('advapi32', 'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)') or croak("Could not import SystemFunction036: $^E");

		$ret = chr(0) x $count;
		$rand->Call($ret, $count) or croak("Could not read from csprng: $^E");
	} elsif (-r "/dev/urandom") {
		open my $urandom, '<:raw', '/dev/urandom' or croak("Couldn't open /dev/urandom: $!");

		sysread($urandom, $ret, $count) or croak("Couldn't read from csprng: $!");
	} else {
		croak("Unknown operating systen $^O");
	};

	if (length($ret) != $count) {
		croak("Unable to read $count bytes from OS");
	}

	return $ret;
}

# Split a string into an array of smaller length strings
sub str_split {
    my ($string, $chunk_size) = @_;
	my $num_chunks = length($string) / $chunk_size;

    my @ret = ();
	for (my $i = 0; $i < $num_chunks; $i++) {
		my $str = substr($string, $i * $chunk_size, $chunk_size);
		push(@ret, $str);
	}

	return @ret;
}

# Binary to hex for human readability
sub bin2hex {
	my $bytes = shift();
	my $ret   = (unpack("h* ", $bytes));

	return $ret;
}

# Fetch random bytes from the OS supplied method
# /dev/urandom = Linux, Unix, FreeBSD, Mac, Android
# Windows requires the Win32::API call to call CryptGenRandom()
sub _get_os_random_bytes_perl {
	my $count  = shift();
	my $ret    = "";

	if ($^O eq 'MSWin32') {
		require Win32::API;

		my $rand = Win32::API->new('advapi32', 'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)') or croak("Could not import SystemFunction036: $^E");

		$ret = chr(0) x $count;
		$rand->Call($ret, $count) or croak("Could not read from csprng: $^E");
	} elsif (-r "/dev/urandom") {
		open my $urandom, '<:raw', '/dev/urandom' or croak("Couldn't open /dev/urandom: $!");

		sysread($urandom, $ret, $count) or croak("Couldn't read from csprng: $!");
	} else {
		croak("Unknown operating systen $^O");
	};

	if (length($ret) != $count) {
		croak("Unable to read $count bytes from OS");
	}

	return $ret;
}

# Randomly seed the PRNG and warmup
sub seed_with_os_random {
	my ($high, $low, $seed1, $seed2);

	# PCG needs to be seeded with 2x 64bit unsigned integers
	# We fetch 16 bytes from the OS to create the two seeds
	# we need for proper seeding

	my $bytes = os_random_bytes(16);
	my @parts = str_split($bytes, 4);

	if (length($bytes) != 16) {
		my $size = length($bytes);
		die("Did not get enough entropy bytes from OS (got $size bytes)\n");
	}

	# Build the first 64bit seed from the random bytes
	# Cannot use Q because it doesn't exist on 32bit Perls
	$high  = unpack("L", $parts[0]);
	$low   = unpack("L", $parts[1]);
	$seed1 = ($high << 32) | $low;

	# Build the second 64bit seed
	$high  = unpack("L", $parts[2]);
	$low   = unpack("L", $parts[3]);
	$seed2 = ($high << 32) | $low;

	if ($debug) {
		print "RANDOM SEEDS: $seed1 / $seed2\n\n";
	}

	if ($seed1 == 0 && $seed2 == 0) {
		die("ERROR: Seeding from OS failed. Both zero? #91393\n");
	}

	# Seed the PRNG with the values we just created
	Random::Simple::_seed($seed1, $seed2); # C API

	$has_been_seeded = 1;

	warmup(1024);
}

######################################################################
# Below are the public user callable methods
######################################################################

# Get a string of random bytes
sub random_bytes {
	my $num = shift();

	if (!$has_been_seeded) { seed_with_os_random(); }

	my $octets_needed = $num / 4;

	my $ret = "";
	for (my $i = 0; $i < $octets_needed; $i++) {
		my $num = Random::Simple::_rand32(); # C API

		# Convert the integer into a 4 byte string
		$ret .= pack("L", $num);
	}

	$ret = substr($ret, 0, $num);

	return $ret;
}

# Get a random non-biased integer in a given range (inclusive)
# Note: Range must be no larger than 2^32 - 2
sub random_int {
	my ($min, $max) = @_;

	if (!$has_been_seeded) { seed_with_os_random(); }

	if ($max < $min) { die("Max can't be less than min"); }

	my $range = $max - $min + 1; # +1 makes it inclusive
	my $ret   = _bounded_rand($range);
	$ret      += $min;

	return $ret;
}

# Get a random float between 0 and 1 inclusive
sub random_float {
	if (!$has_been_seeded) { seed_with_os_random(); }

	my $max = 2**32 - 1;
	my $num = Random::Simple::_rand32(); # C API
	my $ret = $num / $max;

	#print "$num / $max = $ret\n";

	return $ret;
}

# Pick a random element from an array
sub random_elem {
	if (!$has_been_seeded) { seed_with_os_random(); }

	my @arr = @_;

	my $elem_count = scalar(@arr) - 1;
	my $idx        = random_int(0, $elem_count);
	my $ret        = $arr[$idx];

	return $ret;
}

sub perl_rand64 {
	my $high = rand() * 4294967295;
	my $low  = rand() * 4294967295;

	my $ret = ($high << 32) | $low;

	return $ret;
}

# Our srand() overrides CORE::srand()
sub srand {
	my $seed = int($_[0] || 0);

	if ($seed == 0) {
		$seed = int(rand() * 4294967295); # Random 32bit int
	}

	# Convert the one 32bit seed into 2x 64bit seeds
	my $seed1 = _hash64($seed , 64); # C API
	my $seed2 = _hash64($seed1, 64); # C API

	Random::Simple::seed($seed1, $seed2);

	return $seed;
}

# Our rand() overrides CORE::rand()
# This is slightly different than random_float because it returns
# a number where: 0 <= x < 1
#
# This prototype is required so we can emulate CORE::rand(@array)
sub rand(;$) {
	my $mult = shift() || 1;

	if (!$has_been_seeded) { seed_with_os_random(); }

	my $max  = 2**32 - 2; # minus 2 so we're NOT inclusive
	my $rand = Random::Simple::_rand32(); # C API
	my $ret  = $rand / $max;

	$ret = $ret * $mult;

	return $ret;
}

#############################################################

=encoding utf8

=head1 NAME

Random::Simple - Generate good random numbers in a user consumable way.

=head1 SYNOPSIS

    use Random::Simple;

    my $coin_flip      = random_int(1, 2);
    my $die_roll       = random_int(1, 6);
    my $random_percent = random_float() * 100;
    my $buffer         = random_bytes(8);

    my @arr            = ('red', 'green', 'blue');
    my $rand_item      = random_elem(@arr);

=head1 DESCRIPTION

Perl's internal C<rand()> function uses C<drand48> which is an older
pseudorandom number generator and may have limitations. C<Random::Simple> uses
PCG which is: modern, simple, well vetted, and fast. Using C<Random::Simple>
will automatically upgrade/override the core C<rand()> function to use a
better PRNG.

C<Random::Simple> is automatically seeded with entropy directly
from your OS. On Linux this is C</dev/urandom> and on Windows it uses
CryptGenRandom.

When you `use Random::Simple` we automatically upgrade `rand()` and `srand()`
to use a modern PRNG with better statistical properties. As a bonus you also
get a handful of other useful random related methods.

=head1 METHODS

=over 4

=item B<random_int($min, $max)>

returns a non-biased integer between C<$min> and C<$max> (inclusive). Range must be no larger than 2**32 - 2.

=item B<random_float()>

returns a random floating point value between 0 and 1 (inclusive).

=item B<random_bytes($number)>

returns a string of random bytes with length of C<$number>.

=item B<random_elem(@array)>

returns a random element from C<@array>.

=item B<srand()>

emulates C<CORE::srand()> using a better PRNG.

=item B<rand()>

emulates C<CORE::rand()> using a better PRNG.

=item B<Random::Simple::seed($seed1, $seed2)>

Seed the PRNG with two unsigned 64bit integers for predictable and repeatable
random numbers. C<Random::Simple> will automatically seed itself from your
operating system's randomness if not manually seeded. Manual seeding should
only be used in specific cases where you need repeatable or testable
randomness.

=back

=head1 CAVEATS

PCG uses two 64bit unsigned integers for seeding. High quality seeds are needed
to generate good random numbers. C<Random::Simple> automatically generates high
quality seeds by reading random bytes from your operating system and converting
appropriately.

If you manually seed C<Random::Simple>, then make sure you use good seeds that
are mostly non-zero. The larger the number the better seed it will make. A good
seed is a decimal number with 18 or 19 digits.

=head1 BUGS

Submit issues on Github: L<https://github.com/scottchiefbaker/perl-Random-Simple/issues>

=head1 SEE ALSO

=over

=item *
L<Math::Random::PCG32>

=item *
L<Math::Random::ISAAC>

=item *
L<Math::Random::MT>

=item *
L<Math::Random::Secure>

=back

=head1 AUTHOR

Scott Baker - L<https://www.perturb.org/>

=cut

1;
