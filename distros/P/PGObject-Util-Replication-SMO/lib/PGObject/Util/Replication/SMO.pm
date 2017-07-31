package PGObject::Util::Replication::SMO;

use 5.006;
use strict;
use warnings;
use Moo;
use DBI;
use Carp;
use PGObject::Util::PGConfig;
use PGObject::Util::Replication::Slot;

=head1 NAME

PGObject::Util::Replication::SMO - Replication Server Management Objects!

=head1 VERSION

Version 1

=cut

our $VERSION = '1.000000';


=head1 SYNOPSIS

This is intended to be a base class for server management objects for
specific roles (master, standby, etc).  It consolidates the PostgreSQL
logic for these.  It is not currently intended to be directly used
though it could for basic configuration.

    use PGObject::Util::Replication::SMO;
    my $server = PGObject::Util::Replication::SMO->new(); # local pg
    $server->slots(); # replication slots
    my $config = $server->config;

This module provides a wrapper around the config handlers and replication
slots.

=head1 PROPERTIES

=head2 host

Hostname or IP address

=head2 port

defaults to 5432

=head2 user

Username for the connection string.  If not provided, dbi defaults to the
username for the system user of the script running this module

=head2 password

Password for connecting, if needed based on pg_hba.conf settings

=head2 dbname

Database name for connecting. Defaults to postgres

=head2 autocommit

Whether to autocommit statements.  This defaults to true.

=head2 persist_connect

If set, save the connection for repeated use.  Defaults to off
which means we reconnect for each operation.

Set to true if you are doing a lot of operations.

=head2 manage_vars

This is the variables we read or write.  It is intended to be unmodified as it is.

=cut manage_vars

has host => (is => 'ro');
has port => (is => 'ro', default => 5432);
has user => (is => 'ro');
has password => (is => 'ro');
has dbname => (is => 'ro', default => 'postgres');
has autocommit => (is => 'ro', default => 1);
has persist_connect => (is => 'ro', default => 0);
has manage_vars => (is => 'rw', default => sub { _manage_vars() } );
has config => (is => 'lazy');

sub _manage_vars {
    return [qw(
        wal_level fsync synchronous_commit synchronous_standby_names
        wal_sync_method full_page_writes wal_log_hints wal_compression
        wal_buffers archive_mode archive_command archive_timeout
        max_wal_senders max_replication_slots wal_keep_segments
        wal_sender_timeout track_commit_timestamps
    )];
}
sub _build_config {
    my ($self)  = @_;
    return PGObject::Util::PGConfig->new($self->manage_vars, $self->connect);
}

=head1 METHDOS

=head2 connect

Returns a DBI connection to the database and checks to make sure
we are not in recovery.  If we are in recovery, an exception is thrown.

=head2 disconnect

Disconnect, if using persist_connect

=cut

{

 my $pdbh;
 sub connect {
     my ($self) = @_;
     return $pdbh if $pdbh and $self->persist_connect;
     my $dbh = DBI->connect("dbi:Pg:dbname=" . $self->dbname . " port=" . $self->port, $self->user, $self->password, { AutoCommit => $self->autocommit });
     my $sth = $dbh->prepare('select pg_is_in_recovery()');
     $sth->execute;
     $pdbh = $dbh if $self->persist_connect;
     return $dbh;
 }
 sub disconnect {
     $pdbh->disconnect if $pdbh and $pdbh->can('disconnect');
     undef $pdbh;
 }

}

=head1 METHODS

=head2 is_recovering

Returns true if the database is in recovery mode and false if not.  Typically
in replication environments, standby databases will always be in recovery mode
while master systems should generally not be.

=cut

sub is_recovering {
    my ($self) = @_;
    my $dbh = $self->connect();
    my $sth = $dbh->prepare('select pg_is_in_recovery()');
    $sth->execute;
    return ($sth->fetchrow_array)[0];
}

=head2 can_manage

Returns true if the user credentials allow us to create and manage replication slots.

This requires either superuser or replication attributes for the user.

=cut

sub can_manage {
    my ($self) = @_;
    my $dbh = $self->connect();
    my $sth = $dbh->prepare('select rolsuper or rolreplication from pg_roles where rolname = session_user');
    $sth->execute;
    return ($sth->fetchrow_array())[0];
}

=head2 slots([prefix])

Lists all replication slots, their lags, etc.

=cut

sub slots {
    my ($self, $filter) = @_;
    return PGObject::Util::Replication::Slot->all($self->connect, $filter);
}

=head2 getslot($name)

Returns info from a single named slot

=cut

sub getslot {
    my ($self, $name) = @_;
    return PGObject::Util::Replication::Slot->get($self->connect, $name);
}

=head2 addslot

Adds a named replication slot

=cut

sub addslot {
    my ($self, $name) = @_;
    return PGObject::Util::Replication::Slot->create($self->connect, $name);
}

=head2 deleteslot($name)

Deletes a named replication slot

=cut

sub deleteslot {
    my ($self, $name) = @_;
    return PGObject::Util::Replication::Slot->delete($self->connect, $name);
}

=head2 readconfig

Reads all settings from the pg instance.

=head2 addconfig

Adds one more config setting to the managed list and sets it to the default

=head2 setconfig

Sets a config value for later config file writing.

=head2 configcontents

Returns a file of the structure of the config file, based on all managed values.

=cut

sub readconfig {
    my ($self) = @_;
    my $dbh = $self->connect;
    my $sth = $dbh->prepare("
       SELECT name, current_setting(name)
         FROM pg_settings
        WHERE name = any(?)");
    $sth->execute($self->manage_vars);
    my @outlist = ();
    my @next;
    push @outlist, @next while @next = $sth->fetchrow_array;
    my %vars = @outlist;
    $self->config->set($_, $vars{$_}) for keys %vars;

}

sub addconfig {
    my ($self, $name);
    my $manage_ref = $self->manage_vars;
    push @$manage_ref,$name;
    my $sth = $self->connect->prepare("select current_setting(?)");
    $sth->execute($name);
    $self->config->update({$name => $sth->fetchrow_array}); 
}

sub configcontents {
    my ($self) = @_;
    return $self->config->filecontents();
}




=head1 AUTHOR

Chris Travers, C<< <chris.travers at adjust.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-replication-smo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-Replication-SMO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::Replication::SMO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-Replication-SMO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-Replication-SMO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-Replication-SMO>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-Replication-SMO/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Adjust.com

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adjust.com
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::Replication::SMO
