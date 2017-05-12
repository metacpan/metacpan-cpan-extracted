# $Id: 01-resolver.t 1512 2016-10-26 09:14:27Z willem $	-*-perl-*-

use strict;
use Test::More tests => 24;

use Net::DNS;


my $resolver = Net::DNS::Resolver->new( prefer_v4 => 1 );
my $class = ref($resolver);

for (@Net::DNS::Resolver::ISA) {
	diag $_ unless /[:]UNIX$/;
}

ok( $resolver->isa('Net::DNS::Resolver'), 'new() created object' );

ok( $resolver->print, '$resolver->print' );

ok( $class->new( debug => 1 )->_diag(@Net::DNS::Resolver::ISA), 'debug message' );

{					## check class methods
	ok( $class->domain('example.com'),     'class->domain' );
	ok( $class->searchlist('example.com'), 'class->searchlist' );
	$class->nameservers(qw(127.0.0.1 ::1));
	ok( $class->srcport(1234), 'class->srcport' );
	ok( $class->string(),	   'class->string' );
}


{					## check instance methods
	ok( $resolver->domain('example.com'),	  'resolver->domain' );
	ok( $resolver->searchlist('example.com'), 'resolver->searchlist' );
	$resolver->nameservers(qw(127.0.0.1 ::1));
	ok( $resolver->nameservers(), 'resolver->nameservers' );
	ok( $resolver->nameserver(),  'resolver->nameserver' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->force_v6(1);
	ok( !$resolver->nameservers(qw(127.0.0.1)), 'no IPv4 nameservers' );
	like( $resolver->errorstring, '/IPv4.+disabled/', 'errorstring: IPv4 disabled' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->force_v4(1);
	ok( !$resolver->nameservers(qw(::)), 'no IPv6 nameservers' );
	like( $resolver->errorstring, '/IPv6.+disabled/', 'errorstring: IPv6 disabled' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	foreach my $value (qw(1.2.3.4 ::1 ::1.2.3.4)) {
		is( $resolver->srcaddr($value), $value, "resolver->srcaddr($value)" );
	}
}


{					## exercise possibly unused socket code
	my $resolver = Net::DNS::Resolver->new();
	foreach my $value (qw(127.0.0.1 ::1)) {
		my $udp = eval { $resolver->_create_udp_socket($value) };
		ok( !$@, "resolver->_create_udp_socket($value)" );
		my $tcp = eval { $resolver->_create_tcp_socket($value) };
		ok( !$@, "resolver->_create_tcp_socket($value)" );
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

