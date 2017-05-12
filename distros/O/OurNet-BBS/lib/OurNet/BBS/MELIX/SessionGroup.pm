# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MELIX/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MELIX::SessionGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE3::SessionGroup/;
use fields qw/lastref _ego _hash/;
use subs qw/refresh_meta shminit STORE message_handler DESTROY/;
use constant IsWin32 => ($^O eq 'MSWin32');

use OurNet::BBS::Base (
     '$packstring'	=> 'LLLLLLLLa18Z13Z13Z24Z34x2',
     '$packsize'	=> 136,
     '@packlist'	=> [
      qw/pid uid idle_time mode ufo sockaddr sockport destuip msgs userid
	 mateid username from/
     ],
);

use OurNet::BBS::ShmArray;

sub refresh_meta {
    my ($self, $key) = @_;

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});

    if ($key eq int($key)) {
	no strict 'vars';

        print "new toy called $key\n" 
	    if !$self->{_hash}{$key} and $OurNet::BBS::DEBUG;

        $self->{_hash}{$key} ||= $self->module('Session')->new({
	      recno	=> $key,
	      shmid	=> $self->{shmid},
	      shm	=> $self->{shm},
	      chatport	=> $self->{chatport},
	      registered=> $registered{$self} ||= {},
	      passwd	=> $self->{passwd},
	});

        return;
    }
}

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and $self->{shmid} = shmget(
	$self->{shmkey}, ($self->{maxsession}) * $packsize + 36, 0)
    ) {
	tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
	    $self->{shmid}, $self->{maxsession} * $packsize     , 4, 'L';
	tie $self->{shm}{offset}, 'OurNet::BBS::ShmScalar',
	    $self->{shmid}, $self->{maxsession} * $packsize +  4, 4, 'L';
	tie @{$self->{shm}{sysload}}, 'OurNet::BBS::ShmArray',
	    $self->{shmid}, $self->{maxsession} * $packsize +  8, 8, 3, 'd';
	tie $self->{shm}{avgload}, 'OurNet::BBS::ShmScalar',
	    $self->{shmid}, $self->{maxsession} * $packsize + 32, 4, 'L';
	tie $self->{shm}{mbase}, 'OurNet::BBS::ShmScalar',
	    $self->{shmid}, $self->{maxsession} * $packsize + 36, 4, 'L';
	tie @{$self->{shm}{mpool}}, 'OurNet::BBS::ShmArray',
	    $self->{shmid}, $self->{maxsession} * $packsize + 40, 100, 128,
		'LLLLZ13Z71';

	no strict 'vars';
	$instances{$self} = $self;
    }
}

sub message_handler {
    no strict 'vars';

    # we don't handle multiple messages in the queue yet.

    foreach my $instance (values %instances) {
	print "checking $instance $instance->{shm}{offset}\n"
	    if $OurNet::BBS::DEBUG;

        $instance->refresh_meta($_)
            foreach (0 .. $instance->{shm}{offset} / $packsize);

        foreach my $session (values %{$registered{$instance}}) {
            $session->refresh_meta;

            if (my $which = $session->{_hash}{pmsgs}[0]) {
		my %msg;

		@msg{qw/btime caller sender reciever userid message/} =
		    @{$instance->{shm}{mpool}[$which - 1]};

                my $from = $msg{sender} && ( grep {
		    $_->{pid} && $_->{uid} == $msg{sender}
		} @{$instance->{_hash}}{
		    0 .. $instance->{shm}{offset} / $packsize
		})[0];

                $session->dispatch($from, $msg{message});
            }
        }
    }

    $SIG{USR2} = \&message_handler unless IsWin32;
};

$SIG{USR2} = \&message_handler unless IsWin32;

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    if (!length($key)) {
        undef $key;

        for my $newkey (0 .. $self->{maxsession} - 1) {
            $self->refresh_meta($newkey);
	    print "slot $newkey pid = $self->{_hash}{$newkey}{pid}"
		if $OurNet::BBS::DEBUG;
            ($key ||= $newkey, last) unless $self->{_hash}{$newkey}{pid};
        }

        print "new session slot $key...$self->{shm}{offset}\n"
	    if $OurNet::BBS::DEBUG;

	$self->{shm}{offset} += $packsize
	    if $key * $packsize >= $self->{shm}{offset};

        print "new offset...$self->{shm}{offset}\n"
	    if $OurNet::BBS::DEBUG;
    }

    die "no more session $key" unless defined $key;

    $self->refresh_meta($key);
    $value->{pid} ||= $$;
    %{$self->{_hash}{$key}} = %{$value};
    $self->{_hash}{$key}{flag} = 1;
    ++$self->{shm}{number};

    $self->{lastref} = $value->{ref} = $self->{_hash}{$key};
}

# XXX crude hack; returns the previous created session.
sub lastref { shift->ego->{lastref} }

sub DESTROY {
    my $self = shift->ego;

    no strict 'vars';

    delete $instances{$self};
}

1;
