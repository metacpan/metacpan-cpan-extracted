package RT::Extension::Converter::RT1;

use warnings;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(config _handle ));

use RT::Extension::Converter::RT1::Config;
use DBI;

=head1 NAME

RT::Extension::Converter::RT1 - Handle the RT1 side of a conversion


=head1 SYNOPSIS

    use RT::Extension::Converter::RT1;
    my $converter = RT::Extension::Converter::RT1->new;

=head1 DESCRIPTION

Object that should be used by converter scripts to 

=head1 METHODS

=head2 new

Returns a converter object after setting up things such as the config

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->config(RT::Extension::Converter::RT1::Config->new);
    return $self;
}

=head2 config 

Returns a config object

=head2 _handle

private method for the db handle of the RT1 database

=head2 _connect

conect to the RT1 database

=cut

# this probably really wants to be using DBIx::SearchBuilder or
# some other ORM, but we're really just doing a few simple SQL calls
# so we'll avoid having to map the old tables for now

sub _connect {
    my $self = shift;
    my $config = $self->config;
    
    my $dsn = sprintf("DBI:mysql:database=%s;host=%s;",
                      $config->database, $config->dbhost,
                      { RaiseError => 1 });
    print "connecting to $dsn" if $config->debug;
    my $dbh = DBI->connect($dsn, $config->dbuser, $config->dbpassword) 
        or die "Can't connect to RT1 database: ".$DBI::errstr;

    return $self->_handle($dbh);
}

=head2 _run_query

Takes a sql string and a list of placeholder values

 _run_query( sql => $sql, placeholders => \@placeholders )

Returns a statement handle

=cut

sub _run_query {
    my $self = shift;
    my %args = @_;

    my $handle= $self->_handle|| $self->_connect;

    my @placeholders = @{$args{placeholders}||[]};
    
    my $sth = $handle->prepare($args{sql});
    $sth->execute(@placeholders) or 
      die("Can't run query: $args{sql} - " . 
          join(" ",@placeholders) . 
          "\nReason:" . $DBI::errstr . "\n");
    
    return $sth;
}

=head3 _fetch_data 

wrapper around _run_query to hide the boring
bits of iterating over the data set and 
cleaning up when we get to the end of the data.

=cut

sub _fetch_data {
    my $self = shift;
    my %args = @_;
    my $name = delete $args{name};

    my $sth = $self->_sth($name);

    unless ($sth) {
        $sth = $self->_run_query( %args );
        $self->_sth( $name => $sth );
    }

    my $data = $sth->fetchrow_hashref;

    $self->_clean_sth($name) unless $data;

    return $data;
}

=head2 _sth

Stores several named sth's for this object (since multiple queries
can be happening simultaneously).

Takes 
 Name => sth for set
 Name for get

=cut

sub _sth {
    my $self = shift;

    if (@_ > 1) {
        my ($name,$sth) = @_;
        $self->{sths}{$name} = $sth;
    } elsif (@_) {
        my $name = shift;
        $self->{sths}{$name};
    } else {
        die "You must pass at least a name to _sth";
    }
}

=head3 _clean_sth

finishes the sth and gets rid of it
takes the name of the sth

=cut

sub _clean_sth {
    my $self = shift;
    my $name = shift;

    $self->_sth($name)->finish;
    $self->_sth($name,undef);
    return;
}

=head2 get_user

Intended to be called in a loop.
Wraps over the DBH iterator.  When called for the first time, 
will fetch the users and returns one as a hashref.  
Will keep returning one until we run out.

=cut

sub get_user {
    my $self = shift;

    my $sql = <<ESQL;
select user_id as Name, 
       real_name as RealName, 
       password as Password, 
       email as EmailAddress, 
       phone as WorkPhone, 
       comments as Comments, 
       admin_rt as SuperUser
from users
ESQL

    my $user_data = $self->_fetch_data( name => 'User', sql => $sql );

    if ($user_data && !$user_data->{EmailAddress}) {
        $user_data->{EmailAddress} = $user_data->{Name}.'@'.$self->config->email_domain;
    }

    return $user_data;
}

=head3 get_queue

Intended to be called in a loop.
Wraps over the DBH iterator.  When called for the first time, 
will fetch the queues and returns one as a hashref.  
Will keep returning one until we run out.

=cut

sub get_queue {
    my $self = shift;

    my $sql = <<ESQL;
select queue_id as Name, 
       mail_alias as CorrespondAddress, 
       comment_alias as CommentAddress, 
       default_prio as InitialPriority, 
       default_final_prio as FinalPriority, 
       default_due_in as DefaultDueIn
from queues
ESQL

    my $queue_data = $self->_fetch_data( name => 'Queue', sql => $sql );

    if ($queue_data) {
        $queue_data->{Description} = "Imported from RT 1.0";
    }

    return $queue_data;

}

=head3 get_area

Intended to be called in a loop.
Wraps over the DBH iterator.  When called for the first time, 
will fetch the areas for the queue and returns one as a hashref.  
Will keep returning one until we run out.

Takes one argument, Name => Queue's Name

=cut

sub get_area {
    my $self = shift;
    my %args = @_;

    my $sql = 'select area from queue_areas where queue_id = ?';

    my $area_data = $self->_fetch_data( name => 'Area', 
                                        sql => $sql, 
                                        placeholders => [$args{Name}] );

    return $area_data;
}

=head3 get_queue_acl

Intended to be called in a loop.
Wraps over the DBH iterator.  When called for the first time, 
will fetch the acls for the queue and returns one as a hashref.  
Will keep returning one until we run out.

Takes one argument, Name => Queue's Name

=cut

sub get_queue_acl {
    my $self = shift;
    my %args = @_;

    my $sql = 'select user_id, display, manipulate, admin from queue_acl where queue_id = ?';

    my $acl_data = $self->_fetch_data( name => 'ACL', 
                                       sql => $sql, 
                                       placeholders => [$args{Name}] );

    return $acl_data;
}

=head3 get_ticket

Intended to be called in a loop.
Wraps over the DBH iterator.  When called for the first time, 
will fetch all tickets and return one as a hashref.  
Will keep returning one until we run out.

=cut

sub get_ticket {
    my $self = shift;
    my %args = @_;

    my $sql = <<SQL;
select serial_num as id,
       effective_sn as EffectiveId,
       status as Status,
       requestors as Requestors,
       owner as Owner,
       subject as Subject,
       priority as Priority,
       final_priority as FinalPriority,
       initial_priority as InitialPriority,
       date_due as Due,
       date_told as Told,
       date_created as Created,
       date_acted as Updated,
       queue_id as Queue,
       area as Area
from each_req 
SQL
    my $ticket_data = $self->_fetch_data( name => 'Ticket', sql => $sql );

    return $ticket_data;
}

=head2 get_transactions 

Takes the ticketid passed in and returns an arrayref
of transaction data.

=cut

sub get_transactions {
    my $self = shift;
    my $ticket_id = shift;
    my $transactions;

    my $sql = 'select * from transactions where serial_num = ? order by trans_date asc';
    while (my $transaction = $self->_fetch_data( name => 'Transaction', 
            sql => $sql, 
            placeholders => [$ticket_id]) ) {
        if ($transaction->{actor} && $transaction->{actor} !~ /\@/) {
            $transaction->{actor} .= '@'.$self->config->email_domain;
        }
        push @$transactions,$transaction;
    }
    return $transactions;
}

=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
