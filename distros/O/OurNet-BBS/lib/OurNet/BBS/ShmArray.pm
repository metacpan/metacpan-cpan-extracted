# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/ShmArray.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::ShmArray;
use strict;
no warnings 'deprecated';

# ($class, $shmid, $pos, $sz, $count, $packstr);
sub TIEARRAY {
    my $class = shift;

    return bless([@_], $class);
}

sub FETCH {
    my ($self, $key) = @_;
    my $buf;
    shmread($self->[0], $buf, $self->[1]+$self->[2]*$key, $self->[2]);
    return [unpack($self->[4], $buf)];
}

sub FETCHSIZE {
    $_[0]->[3];
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $buf = pack($self->[4], @{$value});
    shmwrite($self->[0], $buf, $self->[1]+$self->[2]*$key, $self->[2]);
}

1;
