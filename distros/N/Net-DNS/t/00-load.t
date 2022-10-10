#!/usr/bin/perl
# $Id: 00-load.t 1875 2022-09-23 13:41:03Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;

my @module = qw(Net::DNS);

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


plan tests => 20 + scalar(@Net::DNS::EXPORT);


use_ok('Net::DNS');

is( Net::DNS->version, $Net::DNS::VERSION, 'Net::DNS->version' );


#
# Check on-demand loading using this (incomplete) list of RR packages
my @rrs = qw( A AAAA CNAME MX NS NULL PTR SOA TXT );

sub is_rr_loaded {
	my $rr = shift;
	return $INC{"Net/DNS/RR/$rr.pm"} ? 1 : 0;
}

#
# Make sure that we start with none of the RR packages loaded
foreach my $rr (@rrs) {
	ok( !is_rr_loaded($rr), "not yet loaded Net::DNS::RR::$rr" );
}

#
# Check that each RR package is loaded on demand
local $SIG{__WARN__} = sub { };					# suppress warnings

foreach my $rr (@rrs) {
	my $object = eval { Net::DNS::RR->new( name => '.', type => $rr ); };
	diag($@) if $@;						# report exceptions

	ok( is_rr_loaded($rr), "loaded package Net::DNS::RR::$rr" );
}


#
# Check that Net::DNS symbol table was imported correctly
foreach my $sym (@Net::DNS::EXPORT) {
	ok( defined &{$sym}, "$sym is imported" );
}


exit;

__END__

