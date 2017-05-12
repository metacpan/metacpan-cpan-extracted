# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/BoardGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE3::BoardGroup;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS::MAPLE2::BoardGroup/;
use fields qw/_ego _hash/;
use subs qw/shminit EXISTS readok writeok/;
use OurNet::BBS::Base (
    '$packstring' => 'Z13Z49Z37CLLLLLLL',
    '$packsize'   => 128,
    '@packlist'   => [
        qw/id title bm bvote bstamp readlevel postlevel
           battr btime bpost blast/
    ],
    '$BRD'        => '.BRD',
    '$PATH_BRD'   => 'brd',
    '$PATH_GEM'   => 'gem/brd',
);

sub writeok {
    my ($self, $user) = @_;

    return $user->has_perm('PERM_BOARD');
}

sub readok {
    my ($self, $user, $op, $argref) = @_;

    # reading a board requires checking against its 'read' permission
    my $readlevel = $self->{$argref->[0]}{readlevel};
    return (!$readlevel or $readlevel & $user->{userlevel});
}

sub shminit {
    my $self = shift;

    if ($^O ne 'MSWin32' and $self->{shmid} = shmget(
	$self->{shmkey}, $self->{maxboard}*$packsize+8, 0
    )) {
        tie $self->{shm}{number}, 'OurNet::BBS::ShmScalar',
           $self->{shmid}, $self->{maxboard}*128, 4, 'L';
        tie $self->{shm}{uptime}, 'OurNet::BBS::ShmScalar',
            $self->{shmid}, $self->{maxboard}*128+4, 4, 'L';
    }

    print "shmid = $self->{shmid} number: $self->{shm}{number}\n"
	if $OurNet::BBS::DEBUG;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return ((-d "$self->{bbsroot}/$PATH_BRD/$key") ? 1 : 0);
}

1;
