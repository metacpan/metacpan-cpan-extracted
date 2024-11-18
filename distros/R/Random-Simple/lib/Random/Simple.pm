package Random::Simple;

our $VERSION = '0.10';
our $debug   = 0;

use strict;
use warnings;
use Time::HiRes;
use Carp qw(croak);

#############################################################

require XSLoader;

XSLoader::load();

use Exporter 'import';
our @EXPORT = qw(random_int random_bytes random_float);

#############################################################

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

# Randomly seed the PRNG and warmup
sub seed_with_os_random {
	my ($high, $low, $seed1, $seed2);

	# Build the first 64bit seed manually
	# Cannot use Q because it doesn't exist on 32bit Perls
	$high  = unpack("L", os_random_bytes(4));
	$low   = unpack("L", os_random_bytes(4));
	$seed1 = ($high << 32) | $low;

	# Build the second 64bit seed
	$high  = unpack("L", os_random_bytes(4));
	$low   = unpack("L", os_random_bytes(4));
	$seed2 = ($high << 32) | $low;

	if ($debug) {
		print "SEEDING RANDOMLY: $seed1 / $seed2\n";
	}

	# Seed the PRNG with the values we just created
	_seed($seed1, $seed2);

	$has_been_seeded = 1;

	warmup(1024);
}

sub random_bytes {
	my $num = shift();

	if (!$has_been_seeded) { seed_with_os_random(); }

	my $octets_needed = $num / 4;

	my $ret = "";
	for (my $i = 0; $i < $octets_needed; $i++) {
		my $num = _rand32();

		# Convert the integer into a 4 byte string
		$ret .= pack("L", $num);
	}

	$ret = substr($ret, 0, $num);

	return $ret;
}

sub random_int {
	my ($min, $max) = @_;

	if (!$has_been_seeded) { seed_with_os_random(); }

	if ($max < $min) { die("Max can't be less than min"); }

	my $range = $max - $min + 1; # +1 makes it inclusive
	my $ret   = _bounded_rand($range);
	$ret      += $min;

	return $ret;
}

sub random_float {
	if (!$has_been_seeded) { seed_with_os_random(); }

	my $max = 2**31 - 1;
	my $num = random_int(0, $max);
	my $ret = $num / $max;

	#print "$num / $max = $ret\n";

	return $ret;
}

#############################################################

=encoding utf8

=head1 NAME

Random::Simple - Generate good random numbers in a user consumable way.

=head2 Why Random::Simple?

To make generating random numbers as easy as possible I<and> in a manner that
you can use in real code. Generate "good" random numbers without having to
think about it.

=head2 Usage

    use Random::Simple;

    my $integer = random_int($min, $max); # inclusive
    my $float   = random_float();         # 0 - 1 inclusive
    my $bytes   = random_bytes($count);   # string of X bytes

	my $die_roll       = random_int(1, 6);
	my $random_percent = random_float() * 100;
	my $buffer         = random_bytes(8);

=head2 Methodology

Perl's internal C<rand()> function uses C<drand48()> which is an older PRNG,
and may have limitations. `Random::Simple` uses PCG which is: modern, simple,
well vetted, and fast.

C<Random::Simple> is automatically seeded with high quality entropy directly
from your OS. On Linux this is C</dev/urandom> and on Windows it uses
CryptGenRandom. You will get statistically unique random numbers
automatically.

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

1;
