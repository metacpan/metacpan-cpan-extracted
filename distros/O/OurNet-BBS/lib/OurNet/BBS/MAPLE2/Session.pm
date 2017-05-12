# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/Session.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE2::Session;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot recno shmid shm chatport registered myshm _ego _hash/;
use POSIX qw/SIGUSR2/;

use OurNet::BBS::Base (
    'SessionGroup' => [qw/$packsize $packstring @packlist/],
);

sub refresh_meta {
    my ($self, $key) = @_;

    my $buf;
    shmread($self->{shmid}, $buf, $packsize * $self->{recno}, $packsize)
        or die "shmread: $!";
    @{$self->{_hash}}{@packlist} = unpack($packstring, $buf);
}

sub refresh_chat {
    my $self = shift;
    return if exists $self->{_hash}{chat};

    require OurNet::BBS::SocketScalar;
    $self->refresh_meta('userid');

    tie $self->{_hash}{chat}, 'OurNet::BBS::SocketScalar',
        (index($self->{chatport}, ':') > -1) ? $self->{chatport}
             : ('localhost', $self->{chatport});

    $self->{_hash}{chat} = "/! 9 9 $self->{_hash}{userid} ".
                                   "$self->{_hash}{userid}\n";
    $self->{_hash}{chatid} = $self->{_hash}{userid};

    $self->_shmwrite();
}

sub _shmwrite {
    my $self = shift;
    shmwrite($self->{shmid}, pack($packstring, @{$self->{_hash}}{@packlist}),
	     $packsize*$self->{recno}, $packsize);
}

sub dispatch {
    my ($self, $from, $message) = @_;

    --$self->{_hash}{msgcount};
    $self->_shmwrite();

    $self->{_hash}{cb_msg} ($from, $message) if $self->{_hash}{cb_msg};
}

sub remove {
    my $self = shift;
    $self->{_hash}{pid} = 0;
    $self->_shmwrite();
    --$self->{shm}{number};
}

sub STORE {
    my ($self, $key, $value) = @_;

    no warnings 'uninitialized';
    print "setting $key $value\n" if $OurNet::BBS::DEBUG;

    if ($key eq 'msg') {
	$self->{_hash}{msgs} =
	    pack('LZ13Z80', getpid(), $value->[0], $value->[1]);
	$self->{_hash}{msgcount}++;
	kill SIGUSR2, $self->{_hash}{pid};
	$self->_shmwrite();

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

    return unless $self->contains($key);
    $self->_shmwrite();
}

sub DESTROY {
    my $self = shift;
    return unless exists $self->{registered}{$self->{recno}};
    $self->{_hash}{pid} = 0;
    $self->_shmwrite();
    delete $self->{registered}{$self->{recno}};
}

1;
