# $Id: 01-resolver.t 1709 2018-09-07 08:03:09Z willem $	-*-perl-*-

use strict;
use Test::More tests => 27;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};


BEGIN {
	eval {
		open( TOUCH, '>.resolv.conf' ) || die $!;	# owned by effective UID
		close(TOUCH);
	};
}


my $resolver = Net::DNS::Resolver->new();
my $class    = ref($resolver);

for (@Net::DNS::Resolver::ISA) {
	diag $_ unless /[:]UNIX$/;
}

ok( $resolver->isa('Net::DNS::Resolver'), 'new() created object' );

ok( $resolver->print, '$resolver->print' );

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


{					## exercise possibly unused socket code
					## check for smoke and flames only
	my $resolver = Net::DNS::Resolver->new( tcp_timeout => 1 );
	foreach my $ip (qw(127.0.0.1 ::1)) {
		eval { $resolver->_create_udp_socket($ip) };
		is( $@, '', "\$resolver->_create_udp_socket($ip)" );
		eval { $resolver->_create_dst_sockaddr( $ip, 53 ) };
		is( $@, '', "\$resolver->_create_dst_sockaddr($ip,53)" );
		eval { $resolver->_create_tcp_socket($ip) };
		is( $@, '', "\$resolver->_create_tcp_socket($ip)" );
	}
}


{					## check for exception on bogus AUTOLOAD method
	eval { $resolver->bogus(); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unknown method:\t[$exception]" );

	is( $resolver->DESTROY, undef, 'DESTROY() exists to defeat pre-5.18 AUTOLOAD' );
}


eval {					## exercise warning for make_query_packet()
	local *STDERR;
	my $filename = '01-resolver.tmp';
	open( STDERR, ">$filename" ) || die "Could not open $filename for writing";
	$resolver->make_query_packet('example.com');		# carp
	$resolver->make_query_packet('example.com');		# silent
	close(STDERR);
	unlink($filename);
};


exit;

__END__

