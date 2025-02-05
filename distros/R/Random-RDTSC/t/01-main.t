use strict;
use warnings;
use Test::More;
use Random::RDTSC qw(get_rdtsc rdtsc_rand64);
use Config;

my $is_64bit = ($Config{use64bitint} || $Config{use64bitall});

# Have to be larger than zero
cmp_ok(get_rdtsc()   , '>', 0);
cmp_ok(rdtsc_rand64(), '>', 0);

# Make sure we're getting real integers
ok(is_int(get_rdtsc()));
ok(is_int(rdtsc_rand64()));

done_testing();

#############################################################

sub is_int {
    my $str = $_[0];
    #trim whitespace both sides
    $str = trim($str);

    #Alternatively, to match any float-like numeric, use:
    # m/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/

    #flatten to string and match dash or plus and one or more digits
    if ($str =~ /^(\-|\+)?\d+?$/) {
		return 1;
    } else{
		return 0;
    }
}

sub trim {
	my ($s) = (@_, $_); # Passed in var, or default to $_
	if (!defined($s) || length($s) == 0) { return ""; }
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

sub get_data {
	my @ret;

	while (my $line = readline(DATA)) {
		$line = trim($line);

		if ($line) {
			push(@ret, $line);
		}
	}

	return @ret;
}
