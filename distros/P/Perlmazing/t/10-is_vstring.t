use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 23;
use Perlmazing qw(is_vstring);

format =
.

our $global = 'our global';

open our $in, '<', $0 or die "Cannot read $0: $!";
my $glob = *main if *main; # avoid 'used once' warning
my $format = *STDOUT{FORMAT};
my $scalar = 'scalar';
my $io = *STDOUT{IO};
my $lvalue = \substr $scalar, 0, 2;
my $regexp = qr[\d];
my $vstring = *main::global{VSTRING};
my $code = sub () { 1 };

my @cases = (
	[\$scalar, 0, 'scalar'],
	[[1..10], 0, 'array'],
	[{my => 'hash'}, 0, 'hash'],
	[$code, 0, 'code'],
	[\$glob, 0, 'glob'],
	[$in, 0, 'filehandle'],
	[\$in, 0, 'ref'],
	[$format, 0, 'format'],
	[$io, 0, 'io'],
	[$lvalue, 0, 'lvalue'],
	[$regexp, 0, 'regexp'],
	[$vstring, 1, 'vstring'],
);
check_cases();

my @ref = @cases;
@cases = ();

for my $i (@ref) {
	my $x = [@$i];
	$x->[1] = 0;
	$x->[2] = "blessed $x->[2]";
	eval {
		$x->[0] = bless $x->[0];
	};
	next if $@;
	next unless ref($x->[0]) eq __PACKAGE__;
	push @cases, $x;
}
check_cases();

close $in;

sub check_cases {
	for my $c (@cases) {
		my $r = is_vstring $c->[0] ? 1 : 0;
		SKIP: {
			skip ('- not really sure about how to test this one', 1) if $c->[1];
			is $r, $c->[1], $c->[2];
		}
	}
}
