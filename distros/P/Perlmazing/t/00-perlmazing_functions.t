use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Perlmazing' ) || print "Bail out!\n";
}

diag( "Testing Perlmazing $Perlmazing::VERSION, Perl $], $^X" );

__END__
my @glob;
if (-d 't') {
	@glob = glob 't/*.t';
} else {
	@glob = glob '*.t';
}

print "glob tiene: ".join("\n", @glob)."\n\n";

my $tests = { map {$_ =~ s/^[\d\-]+//; $_ =~ s/[^\w].*?$//; $_ => 1} @glob };
my $excempt = {
	aes_decrypt		=> 1, # It's tested in aes_encrypt test
	carp			=> 1, # Not necessary, aliased function
	cluck			=> 1, # Not necessary, aliased function
	croak			=> 1, # Not necessary, aliased function
	cwd				=> 1, # Not necessary, aliased function
	get_aes_cipher	=> 1, # Not necessary, internal function
	get_time_from	=> 1, # Not necessary, aliased function
	gmtime			=> 1, # Not necessary, aliased function
	gmtime_hashref	=> 1, # Not necessary, aliased function
	is_leap_year	=> 1, # Not necessary, aliased function
	is_valid_date	=> 1, # Not necessary, aliased function
	localtime		=> 1, # Not necessary, aliased function
	longmess		=> 1, # Not necessary, aliased function
	shortmess		=> 1, # Not necessary, aliased function
	shuffle			=> 1, # Not necessary, aliased function
	sleep			=> 1, # Not necessary, aliased function
	taint			=> 1, # Not necessary, aliased function
	tainted			=> 1, # Not necessary, aliased function
	time_hashref	=> 1, # Not necessary, aliased function
	timegm			=> 1, # Not necessary, aliased function
	timelocal		=> 1, # Not necessary, aliased function
	untaint			=> 1, # Not necessary, aliased function
};

for my $i (sort Perlmazing::Engine->found_symbols('Perlmazing')) {
	next if $i =~ /^_/;
	unless (exists $tests->{$i} or exists $excempt->{$i}) {
		diag "Warning: no tests found for symbol $i - please inform the author";
	}
}

