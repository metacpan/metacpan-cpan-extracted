package Net::DAV::LockManager::DB;

use strict;

use DBI;
use File::Temp qw(tmpnam);
use Net::DAV::Lock;

our $VERSION = '1.305';
$VERSION = eval $VERSION;

#
# This provides a listing of all database schema required to initialize
# a database from an empty state.  Note that this is an array, as each
# schema definition must be executed separately due to limitations in
# the SQLite database driver.
#
my @schema = (
    qq/
        create table lock (
            uuid CHAR(36) PRIMARY KEY,
            expiry INTEGER,
            creator CHAR(128),
            owner CHAR(128),
            depth CHAR(32),
            scope CHAR(32),
            path CHAR(512)
        )
    /
);

#
# Create a new lock manager database context.  Optionally accepts a
# parameter representing a DBI-formatted Data Source Name (DSN).  If no
# DSN is provided, then a temporary SQLite database is used by default.
#
sub new {
    my $class = shift;
    my $dsn = $_[0]? $_[0]: undef;
    my $tmp = undef;

    unless ($dsn) {
        $tmp = File::Temp::tmpnam('/tmp', '.webdav-locks');
        $dsn = 'dbi:SQLite:dbname='. $tmp;
    }

    my $self = bless {
        'db' => DBI->connect($dsn, '', '')
    }, $class;

    #
    # In the event no data source name was passed, take note of this fact in
    # the new object instance so that a proper cleanup can happen at destruction
    # time.
    #
    if ($tmp) {
        $self->{'tmp'} = $tmp;
    }

    #
    # Perform any database initializations that may be required prior to
    # returning the newly-constructed object.
    #
    $self->_initialize();

    return $self;
}

#
# Called from the constructor to initialize state (including database
# file and schema) prior to returning a newly-instantiated object.
#
sub _initialize {
    my ($self) = @_;

    #
    # Enable transactions for the duration of this method.  Enable
    # error reporting.
    #
    $self->{'db'}->{'AutoCommit'} = 0;
    $self->{'db'}->{'RaiseError'} = 1;

    #
    # Only perform initialization if the table definition is missing.
    # We can use the internal SQLite table SQLITE_MASTER to verify
    # the presence of our lock table.
    #
    # If the schema has already been applied to the current database,
    # then we can safely return.
    #
    if ($self->{'db'}->selectrow_hashref(q/select name from sqlite_master where name = 'lock'/)) {
        #
        # Disable transactions and raised errors to revert to default
        # state.
        #
        $self->{'db'}->{'AutoCommit'} = 1;
        $self->{'db'}->{'RaiseError'} = 0;
        return;
    }

    #
    # The schema has not been applied.  Instantiate it.
    #
    eval {
        foreach my $definition (@schema) {
            $self->{'db'}->do($definition);
        }

        $self->{'db'}->commit();
    };

    #
    # Gracefully recover from any errors in instantiating the schema,
    # in this case by throwing another error describing the situation.
    #
    if ($@) {
        warn("Unable to initialize database schema: $@");

        eval {
            $self->{'db'}->rollback();
        };
    }

    #
    # Disable transactions and raised errors to revert to default
    # state.
    #
    $self->{'db'}->{'AutoCommit'} = 1;
    $self->{'db'}->{'RaiseError'} = 0;
}

#
# Intended to be dispatched by the caller whenever the database is no
# longer required.  This method will remove any temporary, one-time
# use databases which may have been created at object instantiation
# time.
#
sub close {
    my ($self) = @_;

    $self->{'db'}->disconnect();

    #
    # If the name of a temporary database was stored in this object,
    # be sure to unlink() said file.
    #
    if ($self->{'tmp'}) {
        unlink($self->{'tmp'});
    }
}

#
# Garbage collection hook to perform tidy cleanup prior to deallocation.
#
sub DESTROY {
    my ($self) = @_;

    $self->close();
}

#
# Given a normalized string representation of a resource path, return
# the first lock found.  Return undef if no object was found in the
# database.
#
sub get {
    my ($self, $path) = @_;

    my $row = $self->{'db'}->selectrow_hashref(q/select * from lock where path = ?/, {}, $path);

    return $row? Net::DAV::Lock->reanimate($row): undef;
}

#
# Given a path string, return any lock objects whose paths are descendants
# of the specified path, excluding the current path.
#
sub list_descendants {
    my ($self, $path) = @_;

    if ($path eq '/') {
        return map {
            Net::DAV::Lock->reanimate($_)
        } @{$self->{'db'}->selectall_arrayref(q(select * from lock where path != '/'), { 'Slice' => {} })};
    }

    my $sql = q/select * from lock where path like ?/;

    return map {
        Net::DAV::Lock->reanimate($_)
    } @{$self->{'db'}->selectall_arrayref($sql, { 'Slice' => {} }, "$path/%")};
}

#
# Given an instance of Net::DAV::Lock, update any entries in the
# database whose path corresponds to the value provided in the
# object.
#
sub update {
    my ($self, $lock) = @_;

    $self->{'db'}->do(q/update lock set expiry = ? where path = ?/, {},
        $lock->expiry,
        $lock->path
    );

    return $lock;
}

#
# Insert the data passed in an instance of Net::DAV::Lock into the
# database, and return that reference.
#
sub add {
    my ($self, $lock) = @_;

    my $sql = qq{
        insert into lock (
            uuid, expiry, creator, owner, depth, scope, path
        ) values (
            ?, ?, ?, ?, ?, ?, ?
        )
    };

    $self->{'db'}->do($sql, {},
        $lock->uuid,
        $lock->expiry,
        $lock->creator,
        $lock->owner,
        $lock->depth,
        $lock->scope,
        $lock->path
    );

    return $lock;
}

#
# Given a Net::DAV::Lock object, the database record which contains the
# corresponding path.
#
sub remove {
    my ($self, $lock) = @_;

    $self->{'db'}->do(q/delete from lock where path = ?/, {}, $lock->path);
}

1;

__END__
Copyright (c) 2010, cPanel, Inc. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
