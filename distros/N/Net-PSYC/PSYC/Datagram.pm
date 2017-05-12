package Net::PSYC::Datagram;

our $VERSION = '0.5';

use strict;
use IO::Socket::INET;

import Net::PSYC qw( watch add W sendmsg same_host send_mmp parse_uniform BLOCKING makeMSG make_psyc parse_psyc parse_mmp PSYC_PORT PSYCS_PORT register_host register_route make_mmp UNL);

sub TRUST {
    return 1;
}

sub new {
    my $class = shift;

    my $addr = shift || undef;		# NOT 127.1
    my $port = int(shift||0) || undef;	# also, NOT 4404

    my %a = (LocalPort => $port, Proto => 'udp');
    $a{LocalAddr} = $addr if $addr;
    my $socket = IO::Socket::INET->new(%a)
	or return $!;
    my $self = {
	'SOCKET' => $socket,
	'IP' => $socket->sockhost,
	'PORT' => $port || $socket->sockport,
	'TYPE' => 'd',
	'I_BUFFER' => '',
	'O_BUFFER' => [],
	'O_COUNT'  => 0,
	'LF' => '',
    };
    W1('UDP bind to %s:%s successful', $self->{'IP'}, $self->{'PORT'});
    bless $self, $class; 

    watch($self) unless (BLOCKING() & 2);
    add($self->{'SOCKET'}, 'w', sub {$self->write()}, 0) 
	unless (BLOCKING() & 1);
    
    return $self;
}

#   send ( target, mc, data, vars ) 
sub send {
    my $self = shift;
    my ( $target, $data, $vars ) = @_;
    W2('send(%s, %s, %s)', $target, $data, $vars);
    
    push(@{$self->{'O_BUFFER'}}, [ [$vars, $data, $target, 0 ] ]);

    if (BLOCKING() || $Net::PSYC::ANACHRONISM) { # send the packet instantly
        return !$self->write(); 
    } else {
        Net::PSYC::Event::revoke($self->{'SOCKET'});
    }
    return 0;
}

sub write () {
    my $self = shift;

    return 1 if (!${$self->{'O_BUFFER'}}[$self->{'O_COUNT'}]);
    
    # get a packet from the buffer
    my $packet = shift(@{${$self->{'O_BUFFER'}}[$self->{'O_COUNT'}]});
    my $target = $packet->[2];
    my ($user, $host, $port, $type, $object) = parse_uniform($target);
    
    $port ||= PSYC_PORT();
    
    $packet->[0]->{'_target'} ||= $target;

# funny, but not what we want.. returns 0.0.0.0 for INADDR_ANY and even
# when the ip is useful, the port may not - the other side should better
# use its own peer info. or the perl app provides _source.
#
#   $vars->{'_source'} |= "psyc://$self->{'IP'}:$self->{'PORT'}/";

    my $m = ".\n"; # empty packet!
    $m .= make_mmp($packet->[0], $packet->[1]);
    
    unless ($host) {
	W0('This target (%s) needs a host. Dropping message.', $target);
	return 1;
    }

    my $taddr = gethostbyname($host); # hm.. strange thing!
    my $tin = sockaddr_in($port, $taddr);
    
    if (!defined($self->{'SOCKET'}->send($m, 0, $tin))) {
	if (++$packet->[3] >= 3) {
	    W0('Delivery of a udp packet to %s failed for the third time. Dropping message.', $target);
	    return 1;
	}
        unshift(@{${$self->{'O_BUFFER'}}[$self->{'O_COUNT'}]}, $packet);
        return 1;
    }
    W1('UDP[%s:%s] <= %s', $host, $port, 
	$packet->[0]->{'_source'} || UNL());
    if (!scalar(@{${$self->{'O_BUFFER'}}[$self->{'O_COUNT'}]})) {
        # all fragments of this packet sent
        splice(@{$self->{'O_BUFFER'}}, $self->{'O_COUNT'}, 1);
        $self->{'O_COUNT'} = 0 if (!${$self->{'O_BUFFER'}}[$self->{'O_COUNT'}]);
    } else {
        # fragments of this packet left
        $self->{'O_COUNT'} = 0 if (!${$self->{'O_BUFFER'}}[++$self->{'O_COUNT'}]);
    }
    if(scalar(@{$self->{'O_BUFFER'}})) {
	if (BLOCKING() || $Net::PSYC::ANACHRONISM) {
	    $self->write();
	} else {
	    Net::PSYC::Event::revoke($self->{'SOCKET'});
	}
    }
    return 1;
}

sub read () {
    my $self = shift;
    my ($data, $last);
    
    $self->{'LAST_RECV'} = $self->{'SOCKET'}->recv($data, 8192); # READ socket

    return if (!$data); # connection lost !?
    # gibt es nen 'richtigen' weg herauszufinden, ob der socket noch lebt?

    $self->{'I_BUFFER'} .= $data;
    delete $self->{'LF'};
    return 1;
}

sub negotiate { 1 }

#   returns _one_ mmp-packet .. or undef if the buffer is empty
sub recv () {    
    my $self = shift;
    if (length($self->{'I_BUFFER'}) > 2) {
	if ( $self->{'LF'} || $self->{'I_BUFFER'} =~ s/^\.(\r?\n)//g ) {
	    
	    $self->{'LF'} ||= $1;
	    my ($vars, $data) = parse_mmp(\$$self{'I_BUFFER'}, $self->{'LF'});
	    return if (!defined $vars);
	    unless (exists $vars->{'_source'}) {
		my ($port, $ip) = sockaddr_in($self->{'LAST_RECV'});
		$vars->{'_source'} = "psyc://$ip:$port";
	    }
	    return ($vars, $data);
	}
	# TODO : we need to provide a proper algorithm to clean up the
	# in-buffer if we got corrupted packets in it. and we need to
	# detect corrupted packets.. udp sucks noodles! ,-)
    }
    return;
}



1;
