# $Id: 00-load.t 1709 2018-09-07 08:03:09Z willem $	-*-perl-*-

use strict;
use Test::More;


my @module = qw(
	Net::DNS
	Net::DNS::SEC
	Data::Dumper
	Digest::BubbleBabble
	Digest::GOST
	Digest::HMAC
	Digest::MD5
	Digest::SHA
	Encode
	File::Spec
	IO::File
	IO::Select
	IO::Socket
	IO::Socket::INET
	IO::Socket::IP
	MIME::Base64
	Net::LibIDN
	Net::LibIDN2
	PerlIO
	Scalar::Util
	Socket
	Time::Local
	Win32::API
	Win32::IPHelper
	Win32::TieRegistry
	);

my @diag;
foreach my $module (@module) {
	eval "require $module";
	my $version = eval { $module->VERSION } || next;
	$version =~ s/(\.\d)$/${1}0/;
	push @diag, sprintf "%-25s  %s", $module, $version;
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
	my $object = eval { new Net::DNS::RR( name => '.', type => $rr ); };
	diag($@) if $@;						# report exceptions

	ok( is_rr_loaded($rr), "loaded package Net::DNS::RR::$rr" );
}


#
# Check that Net::DNS symbol table was imported correctly
{
	no strict 'refs';
	foreach my $sym (@Net::DNS::EXPORT) {
		ok( defined &{$sym}, "$sym is imported" );
	}
}


exit;

__END__

