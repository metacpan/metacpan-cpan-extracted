# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/MAPLE3/UserGroup.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 4012 $ $DateTime: 2003/01/29 11:06:24 $

package OurNet::BBS::MAPLE3::UserGroup;

use open IN => ':raw', OUT => ':raw';

use strict;
no warnings 'deprecated';
use fields qw/bbsroot _ego _hash _array/;
use subs qw/writeok readok/;

use OurNet::BBS::Base (
    '$packstring' => 'iZ13Z14CZ20Z24IiiILLLLZ32iLZ60Z60Z60Z60Z120L',
    '$packsize'   => 512,
    '@packlist'   => [ qw(
	userno userid passwd signature realname username userlevel 
	numlogins numposts ufo firstlogin lastlogin staytime tcheck 
	lasthost numemail tvalid email address justify vmail ident 
	vtime
    ) ],
);

sub writeok { 0 }
sub readok { 1 }

sub FETCHSIZE {
    my $self = $_[0]->ego;

    return (stat("$self->{bbsroot}/.USR"))[7] / 16;
}

# Fetch key: id savemode author date title filemode body
sub refresh_meta {
    my ($self, $key, $flag) = @_;
    my $name;

    if (defined $key) {
        if ($flag == ARRAY) {
            # array fetch
            open(my $DIR, "<$self->{bbsroot}/.USR")
		or die "cannot read $self->{bbsroot}/.USR: $!";
            seek $DIR, $key * 16 + 4, 0;
            read $DIR, $name, 12;
            $name = unpack('Z13', $name);
            close $DIR;
        }
        else {
            # key fetch
            $name = $key;
	    undef $key;
        }

	return if $self->{_hash}{$name};
    }

    my $obj = $self->module('User')->new(
        $self->{bbsroot},
        $name,
        $key,
    );

    $key = $obj->{userno} - 1 unless defined $key;

    $self->{_hash}{$name} = $self->{_array}[$key] = $obj;

    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    my $obj = $self->module('User', $value)->new($self->{bbsroot}, $key);

    while (my ($k, $v) = each %{$value}) {
        $obj->{$k} = $v unless $k eq 'id';
    };

    $self->refresh($key);
}

sub EXISTS {
    my ($self, $key) = @_;
    $self = $self->ego;

    return 1 if exists $self->{_hash}{$key} or -d ("$self->{bbsroot}/usr/".lc(substr($key, 0, 1)."/$key"));
    return 0;

}


1;
