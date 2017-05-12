#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::Pcap qw(:functions);

use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L5::GuessProtocol;
use Net::Inspect::L7::HTTP;
use Net::Inspect::Debug qw(:DEFAULT %TRACE $DEBUG);

my $usage = sub {
    print STDERR <<USAGE;
show live HTTP headers
Usage: $0 -i dev [-p] [-d|--debug] [-T|--trace T]
 -i dev          capture device
 -p              don't put into promiscious mode
 -d|--debug      debugging
 -T|--trace T    Net::Inspect tracing

USAGE
};

my ($dev,$nopromisc);
GetOptions(
    'h|help'      => sub { $usage->() },
    'i=s'         => \$dev,
    'p'           => \$nopromisc,
    'd|debug'     => \$DEBUG,
    'T|trace=s'   => sub { $TRACE{$_}=1 for  split(m/,/, $_[1]) },
) or $usage->();
$dev or $usage->();

my $err;
my $pcap = pcap_open_live($dev,2**16,!$nopromisc,0,\$err);

my $req   = myReq->new;
my $http  = Net::Inspect::L7::HTTP->new($req);
my $guess = Net::Inspect::L5::GuessProtocol->new;
$guess->attach($http);
my $tcp   = Net::Inspect::L4::TCP->new($guess);
my $raw   = Net::Inspect::L3::IP->new($tcp);
my $pc    = Net::Inspect::L2::Pcap->new($pcap,$raw);

# pcap loop
my $time;
pcap_loop($pcap,-1,sub {
    my (undef,$hdr,$data) = @_;
    if ( ! $time || $hdr->{tv_sec}-$time>10 ) {
	$tcp->expire($time = $hdr->{tv_sec});
    }
    return $pc->pktin($data,$hdr);
},undef);

# ------------------------------------------------------------------------ 
package myReq;
use base 'Net::Inspect::L7::HTTP::Request::Simple';
sub in_response_header {
    my ($self,$hdr,$time) = @_;
    print ">>>>>>>\n$hdr\n";
}
sub in_request_header {
    my ($self,$hdr,$time) = @_;
    print "<<<<<<<\n$hdr\n";
}

