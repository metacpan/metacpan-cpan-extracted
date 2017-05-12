use strict;
use warnings;
use IO::Socket::INET;
use Net::INET6Glue::INET_is_INET6;

# check if we can use ::1, e.g if the computer has IPv6 enabled
my $l6;
for my $ioclass (qw(IO::Socket::IP IO::Socket::INET6)) {
    eval "require $ioclass" or next;
    $l6 = $ioclass->new( Listen => 1, LocalAddr => '::1');
    if ( ! $l6 ) {
	print "1..0 # no IPv6 enabled on this computer\n";
	exit
    }
    last;
}

# IPv4 should be still available in the next years
my $l4 = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1' );
if ( ! $l4 ) {
    print "1..0 # no IPv4 on this computer\n";
    exit
}

print "1..2\n";
my $cl4 = IO::Socket::INET->new( '127.0.0.1:'.$l4->sockport );
print ( $cl4 ? "ok\n" : "not ok # connect IPv4\n" );
my $cl6 = IO::Socket::INET->new( '[::1]:'.$l6->sockport );
print ( $cl6 ? "ok\n" : "not ok # connect IPv6: $!\n" );
