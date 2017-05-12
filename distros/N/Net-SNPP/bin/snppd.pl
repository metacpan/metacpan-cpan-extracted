#!/usr/local/bin/perl -w
use strict;
use lib qw( ../lib ); # for testing
use Net::SNPP::Server;
use Sys::Syslog qw(:DEFAULT setlogsock);

setlogsock('unix');
openlog( "snppd.pl", 'pid,cons,ndelay,nowait', 'daemon' )
    or die "could not openlog(): $!";

my $server = Net::SNPP::Server->new(
    Port => 11444,
    Timeout => 60
);

sub write_log_syslog { syslog( shift, join(' ',@_) ); }
sub fake_MSTA {
    return "960 1 20031002100000+6 Message Queued; Awaiting Delivery";
}

$server->callback( 'write_log', \&write_log_syslog );
# lie about MSTA requests and say they're all OK
$server->custom_command( 'MSTA', \&fake_MSTA );

my( $pipe, $pid ) = $server->forked_server();

while ( my $result = $pipe->getline() ) {
    chomp( $result );
    my( $pin, $pin_passwd, %page ) = split( /;/, $result );

    # put your own data storage/forwarding logic here
    print "got page for pin $pin with message '$page{mess}'\n";
}

$pipe->close();

closelog();

# reap the server process
waitpid( $pid, 1 );

exit 0;

