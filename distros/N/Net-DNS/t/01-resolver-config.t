#!/usr/bin/perl
# $Id: 01-resolver-config.t 1896 2023-01-30 12:59:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 23;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};

eval {
	my $fh = IO::File->new( '.resolv.conf', '>' ) || die $!;    # owned by effective UID
	close($fh);
};


my $resolver = Net::DNS::Resolver->new();
my $class    = ref($resolver);

for (@Net::DNS::Resolver::ISA) {
	diag $_ unless /[:]UNIX$/;
}

ok( $resolver->isa('Net::DNS::Resolver'), 'new() created object' );

ok( $class->new( debug => 1 )->_diag(@Net::DNS::Resolver::ISA), 'debug message' );


{					## check class methods
	$class->nameservers(qw(127.0.0.1 ::1));
	ok( scalar( $class->nameservers ), '$class->nameservers' );
	$class->searchlist(qw(sub1.example.com sub2.example.com));
	ok( scalar( $class->searchlist ), '$class->searchlist' );
	$class->domain('example.com');
	ok( $class->domain,	   '$class->domain' );
	ok( $class->srcport(1234), '$class->srcport' );
	ok( $class->string(),	   '$class->string' );
}


{					## check instance methods
	ok( $resolver->domain('example.com'),	  '$resolver->domain' );
	ok( $resolver->searchlist('example.com'), '$resolver->searchlist' );
	$resolver->nameservers(qw(127.0.0.1 ::1));
	ok( scalar( $resolver->nameservers() ), '$resolver->nameservers' );
	$resolver->nameservers();
	is( scalar( $resolver->nameservers() ), 0, 'delete nameservers' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameservers(qw(127.0.0.1 ::1 ::ffff:127.0.0.1 fe80::1234%1));
	$resolver->force_v4(0);					# set by default if no IPv6
	$resolver->prefer_v6(1);
	my ($address) = $resolver->nameserver();
	is( $address, '::1', '$resolver->prefer_v6(1)' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameservers(qw(127.0.0.1 ::1));
	$resolver->force_v6(0);
	$resolver->prefer_v4(1);
	my ($address) = $resolver->nameserver();
	is( $address, '127.0.0.1', '$resolver->prefer_v4(1)' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->force_v6(1);
	ok( !$resolver->nameservers(qw(127.0.0.1)), '$resolver->force_v6(1)' );
	like( $resolver->errorstring, '/IPv4.+disabled/', 'errorstring: IPv4 disabled' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->force_v4(1);
	ok( !$resolver->nameservers(qw(::)), '$resolver->force_v4(1)' );
	like( $resolver->errorstring, '/IPv6.+disabled/', 'errorstring: IPv6 disabled' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	foreach my $ip (qw(127.0.0.1 ::1)) {
		is( $resolver->srcaddr($ip), $ip, "\$resolver->srcaddr($ip)" );
	}
}


{					## check private methods callable
	ok( $resolver->_hints(), 'parse defaults hints RRs' );
	ok( $resolver->_hints(), 'defaults hints accessible' );
}


{					## check for exception on bogus AUTOLOAD method
	eval { $resolver->bogus(); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unknown method:\t[$exception]" );

	is( $resolver->DESTROY, undef, 'DESTROY() exists to placate pre-5.18 AUTOLOAD' );
}


eval {					## no critic		# exercise printing functions
	my $object = Net::DNS::Resolver->new();
	my $file   = "01-resolver.tmp";
	my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $object->print )[0] );
	close($handle);
	unlink($file);
};


exit;

__END__

