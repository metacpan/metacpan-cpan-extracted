# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/GroupGroup.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::GroupGroup;

use strict;
no warnings 'deprecated';
use fields qw/dbh mtime _ego _hash/;

use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    return 1 if (defined($key) and $key =~ /^(?:id|title|owner)$/);

    return $self->{_hash}{$key} ||= $self->module('Group')->new({
	dbh   => $self->{dbh},
	group => $key,
    }) if defined $key;

    return if $self->timestamp(-1);

    # XXX: ALL GROUP FETCH
}

sub DELETE {
    my ($self, $key) = @_;
    $self = $self->ego;

    $self->refresh($key);

    # XXX: GROUP DELETE
    foreach my $keys (values(%{$self->{_hash}})) {
	delete $keys->{$key} if exists $keys->{$key};
    }

    return unless delete($self->{_hash}{$key});
    
    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    ($self, my $flag) = @{${$self}};

    if ($key =~ /^(?:id|title|owner)$/) {
	return $self->{_hash}{$key} = $value;
    }

    $self->refresh($key, $flag);

    if (ref($value)) {
	while (my ($k, $v) = each %{$value}) {
	    $self->{_hash}{$key}{$k} = $v;
	}
    }
    else {
	$self->{_hash}{$key} = $value;
    }

    return 1;
}

1;
