package OpenMuseum;

use 5.006;
use strict;
use warnings FATAL => 'all';
use feature ':5.10';
use YAML qw/LoadFile DumpFile/;
use DBI;

=head1 NAME

OpenMuseum - Data provider or the OpenMusem museum management
system.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

This module is designed to interact with the databases used by
OpenMuseum.  The intent is to provide an object-oriented interface
to the database, abstracting away the SQL heavy lifting.

Use:

    use OpenMuseum;
    $om = OpenMuseum->new(-host => 'localhost', -db => 'openmuseum', -username => 'museum', -password => 'password');
    $stat = $om->authen("username", "passwordhashhere");       #not necessarily a required step
    $rep = $om->report("SELECT id, name, address, email_address, expiry FROM members WHERE expiry LESSTHAN '2022/15/14'" "id");
    # dostuff with the results of the report
    

=head1 METHODS

=head2 new

The new routine returns an initialized OpenMuseum object.

This method takes arguments as a hash constructor.

EG:
    $om = OpenMuseum->new(options here);

These arguments will default, as shown here

-username
    museummate
-password
    ImAVeryBadPassword
-host
    localhost
-db
    openmusem

=cut

sub new{
    my $class = shift;
    my %options = @_;
    my $self = {};
    bless $self, $class;
    $options{-username} ||= 'museummate';
    $options{-password} ||= 'ImAVeryBadPassword';
    $options{-host} ||= 'localhost';
    $options{-db} ||= 'openmuseum';
    $self->{options} = %options;
    $self->initialize();
    return $self;
}

=head2 initialize

Shh, nothing to see here...

This is an internal method used to parse the config file, and
create the database handle used to query the system.

=cut

sub initialize{
    my $self = shift;
    $self->{dbn} = $self->gendbn();
    $self->{dbh} = DBI->connect($self->{dbn}, $self->{options}->{-username}, $self->{options}->{-password});
}

=head2 gendb

Another private method used to construct a DBN for the DBI system.

=cut

sub gendb{
    my $self = shift;
    return "DBI:mysql:".$self->{options}->{-db}.";host=".$self->{options}->{-host};
}

=head2 authfiles

This method returns an array reference being a list of different
entries in an authority file.  it tkesone argument, the name of
an authority file.

=cut

sub authfiles{
    my $self = shift;
    my $file = lc(shift);
    $statement = "SELECT id, item, other FROM authfiles WHERE filename == '$file'";
    return $self->{dbh}->selectall_arrayref($statement);
}

=head2 authen

The authen function is used to authenticate a user, it takes two
parameters: user and password.

=cut

sub authen{
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $query = "SELECT id FROM users WHERE name == $user AND pass == $pass";
    my $res = $self->{dbh}->selectrow_hashref($query, "id");
    if (defined($res)) {
        return $res->{id};
    } else {
        return undef;
    }
}

=head2 options

The options function will get and set options.  It takes two options,
the key and the value, the value is optional and will continue to be
the previous value.  This returns current value of the option $key.

=cut

sub options{
    my $self = shift;
    my $name = shift;
    my $val = shift;
    $self->{options}->{$name} = defined($val) ? $val : $self->{options}->{$name};
    return $self->{options}->{$name};
}

=head2 report

This function performs database reports, and is very handy.  It takes two
arguments, an SQL query and a reference column.  THat is the name of a column
to use as the lookup.  It will either return a hashreference to the results of
the query, or an error if the query was not a 'SELECT' query.

=cut

sub report{
    my $self = shift;
    my $report = shift;
    my $reffield = shift;
    if ($report =~ /^select.*/i) {
        return $self->{dbh}->selectall_hashref($report, $reffield);
    }else {
        return "Bad Report, not select!";
    }
}

=head2 accessions

This routine takes at least one argument, a command.  Possible commands are
query, ids, retrieve, modify, and create.

=head3 query



=head3 retrieve



=head3 ids



=head3 modify



=head3 create



=cut

sub accessions{
    my $self = shift;
    my $type = shift;
    if ($type eq "query") {
    } elsif ($type eq "ids") {
    } elsif ($type eq "retrieve") {
    } elsif ($type eq "modify") {
    } elsif ($type eq "create") {
    } else {
        
    }
}

=head2 multimedia

=cut

sub multimedia{
    my $self = shift;
    my $type = shift;
    if ($type eq "query") {
    } elsif ($type eq "ids") {
    } elsif ($type eq "retrieve") {
    } elsif ($type eq "modify") {
    } elsif ($type eq "create") {
    } else {
        
    }

}

=head2 contacts

=cut

sub contacts{
    my $self = shift;
    my $type = shift;
    if ($type eq "query") {
    } elsif ($type eq "ids") {
    } elsif ($type eq "retrieve") {
    } elsif ($type eq "modify") {
    } elsif ($type eq "create") {
    } else {
        
    }

}

=head2 archive

=cut

sub archive{
    my $self = shift;
    my $type = shift;
    if ($type eq "query") {
    } elsif ($type eq "ids") {
    } elsif ($type eq "retrieve") {
    } elsif ($type eq "modify") {
    } elsif ($type eq "create") {
    } else {
        
    }

}

=head2 exhibits

=cut

sub exhibits{
    my $self = shift;
    my $type = shift;
    if ($type eq "list") {
    } elsif ($type eq "create") {
    } elsif ($type eq "suspend") {
    } elsif ($type eq "display") {
    } elsif ($type eq "edit") {
    } else {
        
    }
}

=head2 objects

=cut

sub objects {

}

=head2 campaigns

=cut

sub campaigns{

}

=head2 tcustody

=cut

sub tcustody{
#temp custody
}

=head2 inloan

=cut

sub inloan{

}

=head2 outloan

=cut

sub outloan{

}

sub deaccession{

}

sub bios{

}

sub sites{

}

=head2 control

=cut

sub control{
    my $self = shift;
    my $type = shift;
}

=head1 AUTHOR

Samuel W. Flint, C<< <linuxkid at linux.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-openmuseum at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenMuseum>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenMuseum


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenMuseum>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenMuseum>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenMuseum>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenMuseum/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Samuel W. Flint.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of OpenMuseum
