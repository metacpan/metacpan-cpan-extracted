package PGObject::Util::Replication::Slot;

use 5.010;
use strict;
use warnings;
use Moo;
use Carp;

=head1 NAME

PGObject::Util::Replication::Slot - Manage and Monitor Replication Slots

=head1 VERSION

Version v0.01

=cut

our $VERSION = 'v0.01';


=head1 SYNOPSIS

This module provides a low-level interface for monitoring and managing
replication slots.  It is intended to be used by other management modules
and therefore requires read and write operations to pass in a database handle.

Slots here represent values and should be treated as read-only once
instantiated.  This is to improve utility when it comes to monitoring and
logging.


    use PGObject::Util::Replication::Slot;

    my @slots = PGObject::Util::Replication::Slot->all($dbh);
    my $slot = PGObject::Util::Replication::Slot->get($dbh, 'slotname');

    # can also create and delete
    my $slot = PGObject::Util::Replication::Slot->create($dbh, 'slotname');
    my $success = PGObject::Util::Replication::Slot->delete($dbh, 'slotname');
    

=head1 SLOT PROPERTIES

Properties are set from the database.  Tthey are not intended to be set
by develoers.

=head2 slot_name

Name of slot. 

=head2 slot_type

logical or physical

=head2 active

boolean

=head2 restart_lsn

Last log serial number sent

=head2 full_data

A json object of the whole pg_replication_slots entry.  You can use this to 
get data not supported by base versions, such as last confirmed wal flush 
on Postgres 9.6.  Note that the format here varies from version to version.

=head2 query_time

The return value of the now() command at the time the query was run.

=head2 pg_current_xlog_location

The current transaction log/wal lsn for the current system.  We will not
change this field here even when running on PostgreSQL 10

=head2 current_lag_bytes

The byte offset between the current xlog logation and the last restart lsn
for the slot.  This means basically the number of bytes that have not yet
been confirmed as read by the slot compared to our current WAL.

=cut


has slot_name => (is => 'ro');
has slot_type => (is => 'ro');
has active => (is => 'ro');
has restart_lsn => (is => 'ro');
has full_data => (is => 'ro');
has query_time => (is => 'ro');
has pg_current_xlog_location => (is => 'ro');
has current_lag_bytes => (is => 'ro');


=head1 METHODS

=head2 all($dbh, [$prefix])

Returns a list of objects fo this type filtered on the prefix specified/

=head2 get($dbh, $name)

Gets the slot specified by name

=head2 create($dbh, $name, [$type])

Creates a new slot, by default a physical one, with the specified name.

=head2 delete($dbh, $name)

Deletes the slot with the given name.  Note that this will allow wal segments 
that are pending to be archived and thus may prevent the replica from being
able to gatch up through normal means.

=cut

my $query = 
"
SELECT slot_name, slot_type, active, restart_lsn, to_jsonb(s) as full_data, 
       now() as querytime, pg_current_xlog_location(), 
       pg_current_xlog_location() - restart_lsn AS current_lag_bytes
  FROM pg_replication_slots s
 WHERE slot_name LIKE ?
 ORDER BY slot_name
";

sub _query {
   my ($dbh, $filter) = @_;
   my $sth = $dbh->prepare($query);
   $sth->execute($filter) or return;
   return $sth->fetchrow_hashref('NAME_lc') unless wantarray;
   my @return = ();
   my $hashref;
   push @return, $hashref while $hashref = $sth->fetchrow_hashref('NAME_lc');
   return @return;
}

sub all {
    my ($self, $dbh, $prefix) = @_;
    $prefix //= '';
    my @items = _query($dbh, $prefix . '%');
    return map { __PACKAGE__->new($_) } @items;
}

sub get {
    my ($self, $dbh, $name) = @_;
    croak 'Must specify which slot to get' unless defined $name;
    my $ref = _query($dbh, $name) or return;
    return __PACKAGE__->new($ref); 
}

sub create {
    my ($self, $dbh, $name, $type) = @_;
    $type //= 'physical';
    $type = lc($type);
    croak 'Slot type must be logical or physical' 
        unless scalar grep { $type eq $_ } qw(logical physical);
    my $sth = $dbh->prepare("SELECT pg_create_${type}_replication_slot(?)");
    $sth->execute($name);
    return __PACKAGE__->get($dbh, $name);
}

sub delete {
    my ($self, $dbh, $name) = @_;
    my $sth = $dbh->prepare("select pg_drop_replication_slot(?)");
    return $sth->execute($name);
}



=head1 AUTHOR

Chris Travers, C<< <chris.travers at adjust.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-replication-slot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-Replication-Slot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::Replication::Slot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-Replication-Slot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-Replication-Slot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-Replication-Slot>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-Replication-Slot/>

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

1; # End of PGObject::Util::Replication::Slot
