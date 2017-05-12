package MooseFS::Server;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

has count => (
    is => 'rw',
    default => sub { 0 }
);

has list => (
    is => 'rw',
    default => sub { [] }
);

has info => (
    is => 'rw',
    default => sub { {} }
);

sub BUILD {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 500, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ( $cmd == 501 and $length % 54 == 0 ) {
        my $data = $self->myrecv($s, $length);
        my $count = $length / 54;
        $self->count($count);
        for my $num ( 0 .. $count - 1 ) {
            my $d = substr($data, $num*54, 54);
            my ($v1, $v2, $v3, $ip1, $ip2, $ip3, $ip4, $port, $used, $total, $chunks, $tdused, $tdtotal, $tdchunks, $errcnt) = unpack('(SCCCCCCSQQLQQLL)>', $d);
            my $percent = $total > 0 ? ($used * 100)/$total : '';
            my $tdpercent = $tdtotal > 0 ? ($tdused * 100)/$tdtotal : '';
            my $ip = "$ip1.$ip2.$ip3.$ip4";
            push @{$self->list}, $ip;
            $self->info->{$ip} = {
                 version => "$v1.$v2.$v3",
                 port => $port,
                 used => $used,
                 total => $total,
                 chunks => $chunks,
                 percent_used => $percent,
                 tdused => $tdused,
                 tdtotal => $tdtotal,
                 tdchunks => $tdchunks,
                 tdpercent_used => $tdpercent,
                 errcnt => $errcnt,
            };
        }
    }
}

1;
