package Samba::Smbstatus;

use 5.006;
use strict;
use warnings;

use Moo;

=head1 NAME

Samba::Smbstatus - Read active Samba server data from smbstatus

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides information about current connections to the local Samba server.

    use Samba::Smbstatus;

    my $smbstats = Samba::Smbstatus->new;
    my $services = $smbstats->services;
    my $users = $smbstats->users;
    my $locks = $smbstats->locks;

=head1 DESCRIPTION

This module reads data from the local Samba server and returns information
about the current users, connections, and resources those users are using.

This information is currently gathered from 

=head1 METHODS

=head2 new()

Create the Samba::Smbstatus object.  Can be called with parameters to
configure the object.

Configuration parameters are:

=over 4

=item smbstatus_binary

Provide a path to the smbstatus binary to use to query the status of the
running server.  Defaults to searching the path for an smbstatus, which some
may consider insecure.

=back

=cut

=head2 smbstatus_binary()

Fetch the name of the smbstatus binary used to query the running Samba
server.  Returns the default value, or the value set at init time.

=cut

has smbstatus_binary => (
    is => 'ro',
    default => sub { 'smbstatus' },
);

has _all_data => (
    is => 'lazy',
    builder => 1,
);

# _build_all_data builds the data needed by the accessors to return
# useful values.  It actually does the work of calling smbstatus and
# parsing the output.
#
# It can be called with a reference to an array, and will use that as the
# output of smbstatus.  If no reference is passed, it will run smbstatus.

sub _build__all_data {
    my $self = shift;
    my $input = shift;

    my @lines;    
    if ($input) {
        @lines = @{$input};
    }
    else {
        my $smbstatus = $self->smbstatus_binary;
        @lines = `$smbstatus 2>/dev/null`;
    }
    chomp @lines;
    
    my $services = [];
    my $users = [];
    my $locks = [];

    my $section = '';
    foreach my $l (@lines) {
        # Trim blanks
        $l =~ s/^\s+//;
        $l =~ s/\s+$//;

        # Blank lines end a section
        if (!length $l) {
            $section = '';
            next;
        }

        # Lines that contain only - are dividers, and can be skipped.
        if ($l !~ /[^-]/) {
            next;
        }

        # Parse for header rows.  If we find one, set the section and advance.
        if ($l =~ /^PID\s+Username\s+Group\s+Machine$/) {
            $section = 'users';
            next;
        }
        if ($l =~ /^Service\s+pid\s+machine\s+Connected\sat$/) {
            $section = 'services';
            next;
        }
        if ($l =~ m!Pid\s+Uid\s+DenyMode\s+Access\s+R/W\s+Oplock\s+SharePath\s+Name\s+Time!) {
            $section = 'locks';
            next;
        }

        # If we made it here, it's not a header.  If we're in a section, try
        # parsing for that section.  If we don't match, the line is ignored.
        if ($section eq 'users' and $l =~ /^(\d+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+\(([\d\.]+)\)/) {
            push @{$users}, {
                pid => $1,
                username => $2,
                group => $3,
                machine => $4,
                ip => $5,
            };
            next;
        }
        
        if ($section eq 'services' and $l =~ m/
            ^
            ([\w\$-]+) # service
            \s+
            (\d+)    # pid
            \s+
            ([\w-]+) # machine
            \s+
            (\w\w\w\s+\w\w\w\s+\d+\s+\d+:\d+:\d+\s+\d+) # date
            $
            /x
            ) {
            push @{$services}, {
                service => $1,
                pid => $2,
                machine => $3,
                connected => $4,
            };
            next;
        }
        
        if ($section eq 'locks' and $l =~ m/
            ^
            (\d+) # Pid
            \s+
            (\d+) # Uid
            \s+
            (\w+) # DenyMode
            \s+
            (0x[\da-fA-F]+) # Access
            \s+
            (\w+)  # RW
            \s+
            ([\w+]+) # Oplock
            \s+
            ([\w\/\d_-]+) # Share
            \s+
            (.*) # Name
            \s+
            (\w\w\w\s+\w\w\w\s+\d+\s+\d+:\d+:\d+\s+\d+) # date
            $  # Date anchored at end, so file gets everything between date and share
            /x
        ) {
            push @{$locks}, {
                pid => $1,
                uid => $2,
                deny_mode => $3,
                access => $4,
                readwrite => $5,
                oplock => $6,
                share => $7,
                name => $8,
                time => $9,
            };
            # Clean up trailing spaces
            $locks->[-1]->{name} =~ s/\s+$//;
            next;
        }
        if ($section ne '') {
            warn "Could not parse line: $l";
        }
        
    }
    $self->{_all_data} = {
        services => $services,
        users => $users,
        locks => $locks,
    };
}

=head2 services()

Returns information about what services are in use by what users.

Returns an array reference of hash references, each of which should have
the following keys:

=over 4

=item service

Name of the service being described by this entry.  Usually a share name,
but can also be printers, named pipes, or other Samba objects.

=item pid

Process ID of the process serving the data.  A client will be connected to
the socket this process has open.

=item machine

Name of the machine or service connected to this resource. Usually a host
name, but sometimes a synthetic client name.

=item connected

Time the client connected to this service.

=back

=cut

sub services {
    my $self = shift;
    return $self->_all_data->{services};
}

=head2 users()

Returns information about what users are connected to the server.

Returns an array reference of hash references, each of which should have
the following keys:

=over 4

=item pid

Process ID of the process serving the data.  A client will be connected to
the socket this process has open.

=item username

Name of the account used by this connection.

=item group

Name of the group used by this connection.

=item machine

Name of the machine or service connected to this resource. Usually a host
name, but sometimes a synthetic client name.

=item ip

IP address this connection is from.

=back

=cut

sub users {
    my $self = shift;
    return $self->_all_data->{users};
}

=head2 locks()

Returns information about what files are locked by the clients on this
Samba server..

Returns an array reference of hash references, each of which should have
the following keys:

=over 4

=item pid

Process ID of the process serving the data.  A client will be connected to
the socket this process has open.

=item uid

User ID used by this connection.  (Not a user name - names can be correlated
by pid from the users data.)

=item deny_mode

Read/write lock requested by this client.  Symbolic names from Samba.  Common
values are:

=over 4

=item DENY_NONE

=item DENY_ALL

=item DENY_READ

=item DENY_WRITE

=item DENY_DOS

=item DENY_FCB

See L<< Using Samba, chapter 5 |
http://oreilly.com/openbook/samba/book/ch05_05.html >> for more description of
what those mean.

=back

=item access

Numeric access code requested for this item.  Displayed as a hexidecimal value.

=item readwrite

Symbolic value describing how this file is being used by the client.  Values
are from Samba.  Known values are:

=over 4

=item RDONLY

=item RDWR

=back

=item oplock

Symbolic values from Samba representing the operational locking mode for
this file.

Known values are:

=over 4

=item NONE

=item EXCLUSIVE+BATCH

=back

=item share

Name of the shared path opened by the client.  This is the path on the
local system.

=item name

Name of the item being used by the system.  It represents a file or directory
on the local sysetm in the share location.

=item time

Time the lock was made by this client.

=back

=cut

sub locks {
    my $self = shift;
    return $self->_all_data->{locks};
}

=head1 AUTHOR

Louis Erickson, C<< <laufeyjarson at laufeyjarson.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-samba-smbstatus at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Samba-Smbstatus>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Samba::Smbstatus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Samba-Smbstatus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Samba-Smbstatus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Samba-Smbstatus>

=item * Search CPAN

L<https://metacpan.org/search?q=Samba%3A%3ASmbstatus>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Louis Erickson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Samba::Smbstatus
