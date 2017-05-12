package Net::DAV::LockManager;

use strict;
use warnings;

use File::Spec ();
use Net::DAV::UUID;
use Net::DAV::Lock;

our $VERSION = '1.305';
$VERSION = eval $VERSION;

sub new {
    my ($class, $db) = (shift, shift);
    my %obj = @_;

    $obj{'db'} = $db;

    return bless \%obj, $class;
}

sub can_modify {
    my ($self, $req) = @_;

    _validate_lock_request( $req, 'user' );

    my ($resource, $token) = @{$req}{qw/path token/};
    my $lock = $self->_get_lock( $resource ) || $self->_get_indirect_lock( $resource );

    return 1 unless $lock;
    return 0 unless $token;

    return _is_permitted( $req, $lock );
}

sub lock {
    my ($self, $req) = @_;

    _validate_lock_request( $req, 'user', 'owner' );

    my $path = $req->{'path'};

    return undef unless $self->can_modify( $req ) && !$self->_get_lock( $path );
    foreach my $lock ( $self->{'db'}->list_descendants( $path ) ) {
        return undef unless _is_permitted( $req, $lock );
    }

    return $self->_add_lock(Net::DAV::Lock->new({
        'path'      => $path,
        (defined $req->{'timeout'} ? ('expiry' => time() + $req->{'timeout'}) : ()),
        'creator'   => $req->{'user'},
        'owner'     => $req->{'owner'},
        (defined $req->{'depth'} ? ('depth' => $req->{'depth'}) : ()),
        (defined $req->{'scope'} ? ('scope' => $req->{'scope'}) : ()),
    }));
}

sub refresh_lock {
    my ($self, $req) = @_;
    _validate_lock_request( $req, 'user', 'token' );

    my $lock = $self->_get_lock( $req->{'path'} );
    return undef unless $lock;
    return undef unless _is_permitted( $req, $lock );

    $lock->renew( time() + ($req->{'timeout'} || $Net::DAV::Lock::DEFAULT_LOCK_TIMEOUT) );

    return $self->_update_lock( $lock );
}

sub unlock {
    my ($self, $req) = @_;
    _validate_lock_request( $req, 'user', 'token' );

    my $lock = $self->_get_lock( $req->{'path'} );
    return 0 unless $lock;
    return 0 unless _is_permitted( $req, $lock );

    $self->_remove_lock( $lock );

    return 1;
}

sub find_lock {
    my ($self, $req) = @_;

    _validate_lock_request( $req );

    my $path = $req->{'path'};

    return $self->_get_lock( $path ) || $self->_get_indirect_lock( $path );
}

sub list_all_locks {
    my ($self, $req) = @_;

    _validate_lock_request( $req );

    my $path = $req->{'path'};
    my @locks;
    my $lock = $self->_get_lock( $path );
    push @locks, $lock if defined $lock;

    while ( $path =~ s{/[^/]+$}{} ) {
        $path = '/' unless length $path;

        my $lock = $self->_get_lock( $path );
        push @locks, $lock if $lock && $lock->depth eq 'infinity';
    }

    return @locks;
}

#
# Retrieve a lock from the lock database, given the path to the lock.
# Return undef if none.  This method also has the side effect of expiring
# any old locks persisted upon fetching.
#
sub _get_lock {
    my ($self, $path) = @_;

    my $lock = $self->{'db'}->get( $path );

    return undef unless $lock;

    if (time() >= $lock->expiry) {
        $self->_remove_lock($lock);

        return undef;
    }

    return $lock;
}

#
# Add the given lock to the database.
#
sub _add_lock {
    my ($self, $lock) = @_;

    return $self->{'db'}->add($lock);
}

#
# Update the lock provided.
#
sub _update_lock {
    my ($self, $lock) = @_;

    return $self->{'db'}->update($lock);
}

#
# Remove the lock object passed from the database.
#
sub _remove_lock {
    my ($self, $lock) = @_;

    $self->{'db'}->remove($lock);

    return 1;
}

#
# Get the lock of the nearest ancestor that applies to this resource.
# Returns undef if none found.
#
sub _get_indirect_lock {
    my ($self, $res) = @_;

    while ( $res =~ s{/[^/]+$}{} ) {
        $res = '/' unless length $res;

        my $lock = $self->_get_lock( $res );
        return $lock if $lock && $lock->depth eq 'infinity';
    }

    return;
}

#
# Return true or false depending on whether or not the information reflected
# in the request is appropriate for the lock obtained from the database.  In
# other words, make sure the token and user match the request.
#
sub _is_permitted {
    my ($req, $lock) = @_;

    return 0 unless $req->{'user'} eq $lock->creator;
    return 0 if !defined $req->{'token'};
    if ( 'ARRAY' eq ref $req->{'token'} ) {
        return 0 unless grep { $_ eq $lock->token } @{$req->{'token'}};
    }
    else {
        return 0 unless $req->{'token'} eq $lock->token;
    }

    return 1;
}

#
# Perform general parameter validation.
#
# The parameter passed in should be a hash reference to be validated.  The
# optional list that follows are names of required parameters besides the
# 'path' and 'user' parameters that are always required.
#
# Throws exception on failure.
#
sub _validate_lock_request {
    my ($req, @required) = @_;
    die "Parameter should be a hash reference.\n" unless 'HASH' eq ref $req;

    foreach my $arg ( qw/path/, @required ) {
        die "Missing required '$arg' parameter.\n" unless exists $req->{$arg};
    }

    die "Not a clean path\n" if $req->{'path'} =~ m{(?:^|/)\.\.?(?:$|/)};
    die "Not a clean path\n" if $req->{'path'} !~ m{^/} && !($req->{'path'} =~ s{^https?://[^/]+/}{/});
    if( defined $req->{'user'} && $req->{'user'} !~ m{^[0-9a-z_.][-a-z0-9_.]*$}i ) {
        die "Not a valid user name.\n";  # May need better validation.
    }

    # Validate optional parameters as necessary.
    if( defined $req->{'scope'} && $Net::DAV::Lock::DEFAULT_SCOPE ne $req->{'scope'} ) {
        die "'$req->{'scope'}' is not a supported value for scope.\n";
    }

    if( defined $req->{'depth'} && '0' ne $req->{'depth'} && 'infinity' ne $req->{'depth'} ) {
        die "'$req->{'depth'}' is not a supported value for depth.\n";
    }

    if( defined $req->{'timeout'} && $req->{'timeout'} =~ /\D/ ) {
        die "'$req->{'timeout'}' is not a supported value for timeout.\n";
    }

    if ( defined $req->{'token'} ) {
        unless ( !ref $req->{'token'} || 'ARRAY' eq ref $req->{'token'} ) {
            die "Invalid token, not a string or array reference.\n";
        }
    }

    # Remove trailing / from path to make pathnames canonical.
    $req->{'path'} =~ s{/$}{} unless $req->{'path'} eq '/';

    return;
}

1;

__END__
Copyright (c) 2011, cPanel, Inc. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

