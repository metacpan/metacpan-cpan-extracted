#!/usr/bin/perl
# $Id: 00-load.t 1924 2023-05-17 13:56:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 3;
use TestToolkit;

my @module = qw(
		Net::DNS
		Net::DNS::SEC
		Net::DNS::SEC::libcrypto
		);

my %metadata;
my $handle = IO::File->new('MYMETA.json') || IO::File->new('META.json');
if ($handle) {
	my $json = join '', (<$handle>);
	for ($json) {
		s/\s:\s/ => /g;					# Perl? en voilà!
		my $hashref = eval $_;
		%metadata = %$hashref;
	}
	close $handle;
}

my %prerequisite;
foreach ( values %{$metadata{prereqs}} ) {			# build, runtime, etc.
	foreach ( values %$_ ) {				# requires
		$prerequisite{$_}++ for keys %$_;
	}
	delete @prerequisite{@module};
	delete $prerequisite{perl};
}

my @diag;
foreach my $module ( @module, sort keys %prerequisite ) {
	eval "require $module";		## no critic
	for ( eval { $module->VERSION || () } ) {
		s/^(\d+\.\d)$/${1}0/;
		push @diag, sprintf "%-25s  %s", $module, $_;
	}
}
diag join "\n\t", "\nThese tests were run using:", @diag;


ok( eval { Net::DNS::SEC::libcrypto->VERSION }, 'XS component SEC.xs loaded' )
		|| BAIL_OUT("Unable to access OpenSSL libcrypto library");

use_ok('Net::DNS::SEC');


# Exercise checkerr() response to failed OpenSSL operation
exception( 'XS libcrypto error', sub { Net::DNS::SEC::libcrypto::checkerr(0) } );

exit;


END {
	eval { Net::DNS::SEC::libcrypto::croak_memory_wrap() }	# paper over crack in Devel::Cover
}


__END__

