#!/usr/bin/perl
# $Id: 00-load.t 1818 2020-10-18 15:24:42Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS::RR::RRSIG;		## preempt Net::DNS::SEC configuration

my @module = qw(
		Net::DNS
		Net::DNS::SEC
		Digest::BubbleBabble
		Digest::HMAC
		Digest::MD5
		Digest::SHA
		Encode
		File::Spec
		IO::File
		IO::Select
		IO::Socket::INET
		IO::Socket::IP
		MIME::Base64
		Net::LibIDN
		Net::LibIDN2
		PerlIO
		Scalar::Util
		Time::Local
		Win32::API
		Win32::IPHelper
		Win32::TieRegistry
		);

my @diag;
foreach my $module (@module) {
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

