# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/Session.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MELIX::Session;

use strict;
no warnings 'deprecated';
use fields qw/recno shmid shm chatid chatport registered userid passwd/,
           qw/_ego _hash/;
use OurNet::BBS::Base (
    'SessionGroup' => [qw/$packsize $packstring @packlist/],
);

use POSIX qw/SIGUSR2/;

sub refresh_meta {
    my ($self, $key) = @_;

    my $buf;
    shmread($self->{shmid}, $buf, $packsize * $self->{recno}, $packsize)
        or die "shmread: $!";

    @{$self->{_hash}}{@packlist} = unpack($packstring, $buf);
    @{$self->{_hash}{pmsgs}} = unpack('S9', $self->{_hash}{msgs});
}

sub refresh_chat {
    my $self = shift;
    return if exists $self->{_hash}{chat};

    require OurNet::BBS::SocketScalar;
    $self->refresh_meta('userid');

    die 'need passwd for session chat' unless $self->{passwd};

    tie $self->{_hash}{chat}, 'OurNet::BBS::SocketScalar',
        (index($self->{chatport}, ':') > -1) ? $self->{chatport}
             : ('localhost', $self->{chatport});

    $self->{_hash}{chat} = "/! $self->{_hash}{userid} ".
			       "$self->{_hash}{userid} ".
                               "$self->{passwd}\n";

    $self->{_hash}{chatid} = $self->{_hash}{userid};
}

sub _shmwrite {
    my $self = shift;

    shmwrite($self->{shmid}, pack($packstring, @{$self->{_hash}}{@packlist}),
	     $packsize*$self->{recno}, $packsize);
}

sub dispatch {
    my ($self, $from, $message) = @_;

    $self->{_hash}{msgs} = pack('S9', 0);
    $self->_shmwrite;
    $self->{_hash}{cb_msg} ($from, $message) if $self->{_hash}{cb_msg};
}

sub remove {
    my $self = shift;

    $self->{_hash}{pid} = 0;
    $self->_shmwrite;
    --$self->{shm}{number};
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    no warnings 'uninitialized';

    if ($key eq 'msg') {
	my $head = $self->{shm}{mbase};
	my ($sendername, $senderid);

	while ($self->{shm}{mpool}[$head][0] > time() - 60) {
	    ++$head;
	}

	$self->{shm}{mbase} = $head;

	# qw/btime caller sender reciever userid message/}
	if (ref($value->[0])) {
	    $senderid = $value->[0]->{uid};
	    $sendername = $value->[0]->{userid};
	}
	else {
	    $sendername = $value->[0];
	}

	$self->{shm}{mpool}[$head] = [
	    time, 0, $senderid, $self->{_hash}{uid}, $sendername, $value->[1]
	];

	$self->{_hash}{msgs} = pack('S', $head + 1);
	$self->_shmwrite;

	kill SIGUSR2, $self->{_hash}{pid};

	return;
    }
    elsif ($key eq 'cb_msg') {
	if (ref($value) eq 'CODE') {
	    print "register callback from $self->{registered}\n"
		if $OurNet::BBS::DEBUG;
	    $self->{registered}{$self->{recno}} = $self;
	}
	else {
	    delete $self->{registered}{$self->{recno}};
	}
    }

    $self->refresh_meta($key);
    $self->{_hash}{$key} = $value;

    $self->_shmwrite if $self->contains($key);

}

sub DESTROY {
    my $self = shift->ego;
    return unless $self->{_hash}{flag};

    $self->{_hash}{pid} = $self->{_hash}{uid} = 0;
    $self->_shmwrite;
    --$self->{shm}{number};

    delete $self->{registered}{$self->{recno}};
}

1;
