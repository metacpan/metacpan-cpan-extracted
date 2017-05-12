package Net::DAV::Lock;

use Net::DAV::UUID;

our $MAX_LOCK_TIMEOUT        = 15 * 60;
our $DEFAULT_LOCK_TIMEOUT    = $MAX_LOCK_TIMEOUT;
our $DEFAULT_DEPTH           = 'infinity'; # as per RFC 4918, section 9.10.3, paragraph 5
our $DEFAULT_SCOPE           = 'exclusive';

our $VERSION = '1.305';
$VERSION = eval $VERSION;

sub new {
    my ($class, $hash) = @_;
    my $obj = {};

    my $now = time();

    die('Missing path value') unless defined $hash->{'path'};
    $obj->{'path'} = $hash->{'path'};

    die('Missing creator value') unless defined $hash->{'creator'};
    die('Owner contains invalid characters') unless $hash->{'creator'} =~ /^[a-z_.][-a-z0-9_.]*$/;
    $obj->{'creator'} = $hash->{'creator'};
    die('Missing owner value') unless defined $hash->{'owner'};
    $obj->{'owner'} = $hash->{'owner'};

    if (defined $hash->{'expiry'}) {
        die('Lock expiry is a date in the past') if $hash->{'expiry'} < $now;
        if ($hash->{'expiry'} - $now > $MAX_LOCK_TIMEOUT) {
            $obj->{'expiry'} = $now + $MAX_LOCK_TIMEOUT;
        }
        else {
            $obj->{'expiry'} = $hash->{'expiry'};
        }
    } elsif (defined $hash->{'timeout'}) {
        if ($hash->{'timeout'} > $MAX_LOCK_TIMEOUT) {
            $obj->{'expiry'} = $now + $MAX_LOCK_TIMEOUT;
        }
        else {
            $obj->{'expiry'} = $now + $hash->{'timeout'};
        }
    } else {
        $obj->{'expiry'} = $now + $DEFAULT_LOCK_TIMEOUT;
    }

    if (defined $hash->{'depth'}) {
        die('Depth is a non-RFC 4918 value') unless $hash->{'depth'} =~ /^(?:0|infinity)$/;
        $obj->{'depth'} = $hash->{'depth'};
    } else {
        $obj->{'depth'} = $DEFAULT_DEPTH;
    }

    if (defined $hash->{'scope'}) {
        die('Scope is an unsupported value') unless $hash->{'scope'} eq 'exclusive';
        $obj->{'scope'} = $hash->{'scope'};
    } else {
        $obj->{'scope'} = $DEFAULT_SCOPE;
    }

    $obj->{'uri'} = $hash->{'uri'};

    #
    # Calculate and store a new UUID based on the path and owner
    # specified, if none is present.
    #
    if ($hash->{'uuid'}) {
        unless ($hash->{'uuid'} =~ /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/) {
            die('UUID is of an invalid format');
        }

        $obj->{'uuid'} = $hash->{'uuid'};
    } elsif ($hash->{'token'}) {
        unless ($hash->{'token'} =~ /^opaquelocktoken:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/) {
            die('Token is not a UUID prefixed with the opaquelocktoken: URI namespace');
        }

        my $uuid = $hash->{'token'};
        $uuid =~ s/^opaquelocktoken://;

        $obj->{'uuid'} = $uuid;
    } else {
        $obj->{'uuid'} = Net::DAV::UUID::generate(@{$hash}{qw/path owner/});
    }

    return bless $obj, $class;
}

#
# Provide a separate constructor for reanimating values from the database,
# especially when the validation within the normal constructor would be
# considered undesired behavior.
#
# Results in a simple copy of the database row into a blessed object.
#
sub reanimate {
    my ($class, $row) = @_;

    bless { %$row }, $class;
}

sub expiry { shift->{'expiry'} };
sub creator { shift->{'creator'} };
sub owner { shift->{'owner'} };
sub depth { shift->{'depth'} };
sub scope { shift->{'scope'} };
sub path { shift->{'path'} };
sub uuid { shift->{'uuid'} };

#
# Return the number of seconds remaining for which this lock is
# valid, relative to the current system time.
#
sub timeout {
    my ($self) = @_;

    my $left = $self->{'expiry'} - time();

    return $left >= 0? $left: 0;
}

#
# Provide a wrapper method to return a token URI based on the UUID
# stored in the current object.
#
sub token {
    my ($self) = @_;

    return 'opaquelocktoken:' . $self->uuid;
}

#
# Update the expiration date of this lock.  Throw an error if the update
# is not for any time in the future.
#
# The rationale for providing this method as a means of setting a new
# value for the lock expiration date is that without it, the immutable
# nature of this class forces the creation of a new lock object, which
# would be undesirable as the existing UUID should be preserved.
#
sub renew {
    my ($self, $expiry) = @_;

    die('New lock expiration date is not in the future') unless $expiry > time();

    $self->{'expiry'} = $expiry;

    return $self;
}

1;

__END__
Copyright (c) 2010, cPanel, Inc. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
