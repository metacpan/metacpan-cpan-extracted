# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/SessionGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE2::SessionGroup;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot shmkey maxsession chatport passwd shmid shm _ego _hash/;
use constant IsWin32 => ($^O eq 'MSWin32');
use constant SIGUSR2 => IsWin32 ? 'INT' : 'USR2';

use OurNet::BBS::Base (
    '%registered' => {},
    '%instances'  => {},
    '$packstring' => 'LLLLLCCCx1LCCCCZ13Z11Z20Z24Z29Z11a256a64LCx3a1000LL',
    '$packsize'   => 1476,
    '@packlist'   => [
        qw/uid pid sockaddr destuid destuip active invisible
           sockactive userlevel mode pager in_chat sig userid
           chatid realname username from tty friends reject
           uptime msgcount msgs mood site/
    ],
);

use OurNet::BBS::ShmScalar;

sub message_handler {
    # we don't handle multiple messages in the queue yet.
    foreach my $instance (values %instances) {
        print "check for instance $instance\n" if $OurNet::BBS::DEBUG;
        $instance->refresh_meta($_)
            foreach (0..$instance->{maxsession}-1);

        foreach my $session (values %{$registered{$instance}}) {
            print "check for $session->{_hash}{pid}\n" if $OurNet::BBS::DEBUG;
            $session->refresh_meta();
            if ($session->{_hash}{msgcount}) {
                my ($pid, $userid, $message) =
                    unpack('LZ13Z80x3', $session->{_hash}{msgs});
                my $from = $pid && (grep {$_->{pid} == $pid}
                    @{$instance->{_hash}}{0..$instance->{maxsession}-1})[0];
                print "pid $pid, from $from\n" if $OurNet::BBS::DEBUG;
                $session->dispatch($from || $userid, $message);
            }
        }
    }

    $SIG{+SIGUSR2} = \&message_handler if SIGUSR2();
};

$SIG{+SIGUSR2} = \&message_handler if SIGUSR2();

sub _lock {}
sub _unlock {}

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
	$self->{shmid} = shmget($self->{shmkey},
				($self->{maxsession})*$packsize+36, 0)) {
      tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
	$self->{shmid}, $self->{maxsession}*$packsize, 4, 'L';
      tie $self->{_hash}{number}, 'OurNet::BBS::ShmScalar',
	$self->{shmid}, $self->{maxsession}*$packsize+4, 4, 'L';
      tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
	$self->{shmid}, $self->{maxsession}*$packsize+8, 4, 'L';
      $instances{$self} = $self;
    }
}

sub refresh_meta {
    my ($self, $key) = @_;

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});

    if ($key eq int($key)) {
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

sub STORE {
    my ($self, $key, $value) = @_;

    die "STORE: attempt to store non-hash value ($value) into ".ref($self)
        unless UNIVERSAL::isa($value, 'HASH');

    unless (length($key)) {
        print "trying to create new session\n" if $OurNet::BBS::DEBUG;

        undef $key;
        for my $newkey (0..$self->{maxsession}-1) {
            $self->refresh_meta($newkey);
            ($key ||= $newkey, last) if $self->{_hash}{$newkey}{pid} < 2;
        }
        print "new key $key...\n" if $OurNet::BBS::DEBUG;
    }

    die "no more session $key" unless defined $key;

    ++$self->{_hash}{number};
    $self->refresh_meta($key);
    %{$self->{_hash}{$key}} = %{$value};

}

sub DESTROY {
    my $self = shift;
    delete $instances{$self};
}

1;
