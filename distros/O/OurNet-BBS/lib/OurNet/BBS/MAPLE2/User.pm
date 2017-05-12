# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE2/User.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE2::User;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot id recno _ego _hash/;
use OurNet::BBS::Base (
    'UserGroup' => [qw/$packsize $namestring $packstring @packlist $PWD/],
);

sub refresh_meta {
    my ($self, $key) = @_;

    $self->{_hash}{uid} ||= $self->{recno} - 1;
    $self->{_hash}{name} ||= $self->{id};
    return if exists $self->{_hash}{$key};

    if ($self->contains($key)) {
	my $buf = '';

	open(my $USR, "<$self->{bbsroot}/$PWD") or die "can't open $PWD";
	seek $USR, $self->{recno} * $packsize, 0;
	read $USR, $buf, $packsize;
	close $USR;

	@{$self->{_hash}}{@packlist} = unpack($packstring, $buf);
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";
    }

    return 1;
}

sub refresh_mailbox {
    my $self = shift;

    $self->{_hash}{mailbox} ||= $self->module('ArticleGroup')->new(
        $self->{bbsroot},
        $self->{id},
        'home',
    );
}

sub STORE {
    my ($self, $key, $value) = @_;

    if ($self->contains($key)) {
 	$self->refresh_meta($key);
	$self->{_hash}{$key} = $value;

	open(my $USR, "+<$self->{bbsroot}/$PWD")
	    or die "can't open $PWD";
	seek $USR, $self->{recno} * $packsize, 0;
        print $USR pack($packstring, @{$self->{_hash}}{@packlist});
	close $USR;
    }
    else {
	die "malicious intent stopped cold" if index($key, '../') > -1;

	require OurNet::BBS::ScalarFile;
	tie $self->{_hash}{$key}, 'OurNet::BBS::ScalarFile',
	    "$self->{bbsroot}/home/$self->{id}/$key";

	$self->{_hash}{$key} = $value;
    }

    return 1;
}

1;

