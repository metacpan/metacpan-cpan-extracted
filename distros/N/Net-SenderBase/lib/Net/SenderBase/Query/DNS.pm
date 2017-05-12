# $Id: DNS.pm,v 1.3 2003/07/03 15:11:04 matt Exp $

package Net::SenderBase::Query::DNS;
use strict;
use vars qw($HOST);

$HOST = 'test.senderbase.org';

use Net::DNS;
use IO::Select;
use Net::SenderBase::Results;

sub new {
    my $class = shift;
    my %attrs = @_;

    $attrs{Address} || die "No address";
    $attrs{Host} ||= $HOST;
    $attrs{Timeout} || die "No timeout";

    my $self = bless { %attrs }, $class;

    my $res = Net::DNS::Resolver->new();
    my $sel = IO::Select->new();

    my $reversed_ip = join('.', reverse(split(/\./,$attrs{Address})));

    my $mask = $attrs{Mask} ? ".$attrs{Mask}" : '';
    
    $sel->add($res->bgsend("$reversed_ip$mask.$attrs{Host}", "TXT"));

    $self->{_sel} = $sel;

    return $self;
}

sub results {
    my $self = shift;

    my $res = Net::DNS::Resolver->new();
    my $sel = $self->{_sel};

    my @ready = $sel->can_read($self->{Timeout});

    @ready || die "Timeout occurred getting results";

    my @lines;
    
    for my $socket (@ready) {
        my $query = $res->bgread($socket);
        $sel->remove($socket);
        undef($socket);

        if (!$query) {
            die $res->errorstring;
        }

        foreach my $rr ($query->answer) {
            next unless $rr->type eq 'TXT';
            my $line = $rr->txtdata;
            if ($line =~ s/^(\d+)-//) {
                my $id = $1;
                $lines[$id] = $line;
            }
            else {
                die "Unable to parse TXT record: $line";
            }
        }
    }

    @lines || die "No results came back for $self->{Address}";
    
    return Net::SenderBase::Results->cons($self->{Address}, join('', @lines));
}

1;
