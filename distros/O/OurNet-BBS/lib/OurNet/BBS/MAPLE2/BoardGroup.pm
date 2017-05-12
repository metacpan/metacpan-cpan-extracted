# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/BoardGroup.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE2::BoardGroup;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot shmkey maxboard shmid shm mtime _ego _hash/;
use OurNet::BBS::ShmScalar;

use OurNet::BBS::Base (
    '$packstring'    => 'Z13Z49Z39Z11LZ3CLL',
    '$namestring'    => 'Z13',
    '$packsize'      => 128,
    '@packlist'      => [
        qw/id title bm pad bupdate pad2 bvote vtime level/
    ],
    '$BRD'           => '.BOARDS',
    '$PATH_BRD'      => 'boards',
    '$PATH_GEM'      => 'man/boards',
);

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and
        $self->{shmid} = shmget($self->{shmkey}, $self->{maxboard} * $packsize + 16, 0)) {
        tie $self->{shm}{touchtime}, 'OurNet::BBS::ShmScalar',
	    $self->{shmid}, $self->{maxboard}*$packsize +  4, 4, 'L';
        tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*$packsize +  8, 4, 'L';
        tie $self->{shm}{busystate}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*$packsize + 12, 4, 'L';
    }
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key) = @_;

    my $file = "$self->{bbsroot}/$BRD";
    my $board;

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});

    if ($key) {
        $self->{_hash}{$key} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $key,
            shmid   => $self->{shmid},
            shm     => $self->{shm},
        });

	print $self->{_hash}{$key}->shmid if $OurNet::BBS::DEBUG;
        return;
    }

    return if $self->filestamp($file);

    open(my $DIR, "<$file") or die "can't read DIR file $file $!";

    foreach (0 .. int((stat($file))[7] / $packsize)-1) {
        read $DIR, $board, $packsize;

	CORE::unpack($namestring, $board) =~ /^([^\0].*)$/ or next;
 	$board = $1; # untaint

        $self->{_hash}{$board} ||= $self->module('Board')->new({
            bbsroot => $self->{bbsroot},
            board   => $board,
            shmid   => $self->{shmid},
            shm     => $self->{shm},
            recno   => $_,
        });
    }

    close $DIR;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;
    return 1 if exists ($self->{_hash}{$key});

    my $file = "$self->{bbsroot}/$BRD";
    return 0 if $self->filestamp($file, 'mtime', 1);

    open(my $DIR, "<$file") or die "can't read DIR file $file: $!";

    my $board;
    foreach (0 .. int((stat($file))[7] / $packsize)-1) {
        read $DIR, $board, $packsize;
	return 1 if CORE::unpack($namestring, $key) eq $key;
    }

    close $DIR;
    return 0;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    die "Need key for STORE" unless $key;

    $self->shminit unless ($self->{shmid} || !$self->{shmkey});
    %{$self->module('Board')->new({
	bbsroot => $self->{bbsroot},
	board   => $key,
	shmid   => $self->{shmid},
	shm     => $self->{shm},
    })} = (%{$value}, bstamp => CORE::time);

    return 1;
}

1;
