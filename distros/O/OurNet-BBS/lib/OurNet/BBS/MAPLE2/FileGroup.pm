# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/FileGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::MAPLE2::FileGroup;

use strict;
no warnings 'deprecated';
use fields qw/bbsroot _ego _hash/;

sub readok() { 1 }

use OurNet::BBS::Base (
    '$PATH_ETC' => 'etc',
);


sub refresh_meta {
    my ($self, $key) = @_;

    die "globbing the etc directory considered harmful."
	unless defined $key;

    return if $self->{_hash}{$key};

    require OurNet::BBS::ScalarFile;
    tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile', 
	"$self->{bbsroot}/$PATH_ETC/$key";

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    no warnings 'uninitialized';

    require OurNet::BBS::ScalarFile;
    tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile', 
	"$self->{bbsroot}/$PATH_ETC/$key";

    $self->{_hash}{$key} = $value;
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return -e ("$self->{bbsroot}/$PATH_ETC/$key");
}

1;
