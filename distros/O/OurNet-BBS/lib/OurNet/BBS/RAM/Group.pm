# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/RAM/Group.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::RAM::Group;

use strict;
no warnings 'deprecated';
use fields qw/dbh group mtime _ego _hash/;

use OurNet::BBS::Base;

sub refresh_meta {
    my ($self, $key) = @_;

    return unless $self->{group};
    return 1 if (defined($key) and $key =~ /^(?:id|title|owner)$/);
    return if $self->timestamp(1);

    # XXX: GROUP FETCH
    return 1;
}

sub DELETE {
    my ($self, $key) = @_;
    $self = $self->ego;

    $self->refresh($key);
    return unless delete($self->{_hash}{$key});
    
    # XXX: GROUP DELETE
    return 1;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self = $self->ego;

    return $self->{_hash}{$key} = $value
	if ($key =~ /^(?:id|title|owner)$/);

    return if exists $self->{_hash}{$key}; # doesn't make sense yet
    
    # XXX: GROUP STORE
    $self->{_hash}{$key} = $self->module('Board')->new({
        dbh   => $self->{dbh},
        board => $key,
    });

    return 1;
}

sub remove {
    my $self = shift;

    # XXX: GROUP REMOVE
    return 1;
}

1;
