############################################################################
# Net::Inspect::L5::Socks
# handle Socks encapsulation (only Socks4 connect currently)
# TODO: bind, Socks5
############################################################################
use warnings;
use strict;
package Net::Inspect::L5::Socks;
use base 'Net::Inspect::Connection';
use fields qw(replay sockshdr meta fwd error);
use Net::Inspect::Debug;
use Socket 'inet_ntoa';

sub guess_protocol {
    my ($self,$guess,$dir,$data,$eof,$time,$meta) = @_;

    if ($data ne '') {
	# keep all calls for replaying later
	my $replay = $self->{replay} ||=[];
	push @$replay,[$dir,$data,$eof,$time];

	if ( $dir == 1 ) { # socks reply?
	    my $buf0 = my $buf1 = '';
	    for(@$replay) {
		if ($_->[0]) {
		    $buf1 .= $_->[1]
		} else {
		    $buf0 .= $_->[1]
		}
	    }
	    goto not_me if length($buf0)<9; # too small for socks4 header
	    my ($ver,$conn,$port,$ip) = unpack('CCna4',$buf0);
	    goto not_me if $ver != 4; # not socks4
	    goto not_me if ! $conn;   # do only connect not bind for now

	    return if length($buf1)<8; # not enough bytes for response
	    ($ver,my $status,$port,$ip) = unpack('CCna4',$buf1);
	    goto not_me if $ver != 0; # no socks4 reply

	    # FIXME - what should we do if status not success?
	    goto not_me if $status != 90;


	    # looks like socks4
	    my $obj = $self->new_connection($meta) or goto not_me;
	    $obj->in(@$_) for(@$replay);
	    return ($obj,length($data));

	    not_me:
	    $guess->detach($self);
	    return;
	}
    }

    return;
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    return length($data) if $self->{error};

    my $bytes = 0;
    if ( ! $self->{fwd} ) {
	# strip socks header
	if ( $dir == 0 ) {
	    if ( ! $self->{sockshdr} ) {
		goto need_more if length($data)<9; # incomplete socks4 header
		my ($ver,$conn,$port,$ip) =
		    unpack('CCna4',substr($data,0,8,''));
		return $self->fatal("only version 4 supported, version=$ver")
		    if $ver != 4;
		return $self->fatal("only connect supported") if ! $conn;

		# strip username\0
		my $null = index($data,"\0");
		if ( $null<0 ) {
		    # username not finished
		    return $self->fatal("username too long") if length($data)>512;
		    goto need_more;
		}
		my $user = substr($data,0,$null+1,'');
		$bytes += 8 + $null + 1;

		$self->{sockshdr} = {
		    daddr => inet_ntoa($ip),
		    dport => $port,
		    socks_user => $user,
		    replay0 => [],
		};

		return $bytes if $data eq ''; # done
	    }

	    # no object yet, e.g. no socks response: buffer data
	    push @{ $self->{sockshdr}{replay0}}, [ $data,$eof,$time ];
	    $bytes += length($data);
	    return $bytes;

	} elsif ( $self->{sockshdr} ) {
	    # socks reply
	    goto need_more if length($data)<8; # incomplete
	    my ($ver,$status,$port,$ip) = unpack('CCna4',substr($data,0,8,''));
	    $ver == 0 or return $self->fatal("invalid version $ver in socks4 reply");
	    my $r0 = delete $self->{sockshdr}{replay0};
	    if ( $status == 90 ) {
		# successful connect
		$self->{fwd} = $self->{upper_flow}->new_connection({
		    %{$self->{meta}},
		    %{$self->{sockshdr}},
		});
		$self->{fwd} ||= Net::Inspect::L5::Socks::IgnoreConnection->new;
	    } else {
		$self->{fwd} = Net::Inspect::L5::Socks::NoData->new;
	    }
	    $self->{fwd}->in(0,@$_) for(@$r0);
	    $bytes += 8;
	    return $bytes if $data eq '';

	} else {
	    $self->fatal("data from server w/o sockshdr from client");
	}
    }

    # got socks header from both sides, just forward to upper layer
    return $bytes + $self->{fwd}->in($dir,$data,$eof,$time);

    need_more:
    $self->fatal("eof inside socks hdr($dir)") if $eof;
    return;
}


sub new_connection {
    my ($self,$meta) = @_;
    my $obj = $self->new;
    $obj->{meta} = $meta;
    return $obj;
}

sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    $self->{error} = 1;
    my $obj = $self->{fwd};
    return $obj->fatal($reason,$dir,$time) if $obj;
    trace($reason);
    return;
}

sub expire {
    my ($self,$time) = @_;
    if ( my $obj = $self->{fwd} ) {
	return $obj->expire($time)
    }
    return $self->SUPER::expire($time);
}


package Net::Inspect::L5::Socks::IgnoreConnection;
{
    my $singleton;
    sub new { return $singleton ||= bless {},shift }
    sub in {
	my ($self,$dir,$data) = @_;
	return length($data);
    }
}


package Net::Inspect::L5::Socks::NoDataConnection;
use base 'Net::Inspect::L5::Socks';
{
    my $singleton;
    sub new { return $singleton ||= bless {},shift }
    sub in {
	my ($self,$dir,$data) = @_;
	return $self->fatal("unexpected data in connection with socks error")
	    if $data ne '';
    }
}


1;

__END__

=head1 NAME

Net::Inspect::L5::Socks - handles empty connections

=head1 SYNOPSIS

 my $guess = Net::Inspect::L5::GuessProtocol->new;
 my $null = Net::Inspect::L5::Socks->new;
 $guess->attach($null);


=head1 DESCRIPTION

This class is usually used together with Net::Inspect::L5::GuessProtocol to
detect and ignore empty connections. It provides a C<guess_protocol> method
which returns a new object if the connection is closed and no data were
transferred.
