# $Id: HTTP.pm,v 1.3 2003/07/08 20:16:44 matt Exp $

package Net::SenderBase::Query::HTTP;
use strict;
use vars qw($HOST);

$HOST = 'www.senderbase.org';

use Socket qw(CRLF);
use IO::Socket;
use Net::SenderBase;
use Net::SenderBase::Results;

sub new {
    my $class = shift;
    my %attrs = @_;
    
    $attrs{Address} || die "No address";
    $attrs{Host} ||= $HOST;
    $attrs{Timeout} || die "No timeout";

    my $self = bless { %attrs }, $class;

    return $self;
}

sub results {
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->{Host},
        PeerPort => '80',
        Proto => 'tcp',
        Timeout => $self->{Timeout},
    ) || die "Connect to $self->{Host}:80 failed";

    my $mask = $self->{Mask} ? "&mask=$self->{Mask}" : '';
    print $socket "GET /check?ip=$self->{Address}$mask HTTP/1.0" , CRLF,
                  "Host: $self->{Host}", CRLF,
                  "User-Agent: Net::SenderBase/$Net::SenderBase::VERSION",
                  CRLF, CRLF;

    local $/ = "\015\012";

    my $proto = <$socket>; # HTTP/1.0 ....
    die "Invalid response" unless $proto =~ /^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)$/;
    my ($ver, $code, $msg) = ($1, $2, $3);

    HEADERS:
    while (<$socket>) {
        chomp;
        last HEADERS if /^$/m;
    }

    my $data = <$socket>;
    die "No results came back for $self->{Address}" unless $data;
    return Net::SenderBase::Results->cons($self->{Address}, $data);
}

1;
