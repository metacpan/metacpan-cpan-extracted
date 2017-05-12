package Solstice::Database;

=head1 NAME

Solstice::Database - Wrapper around DBI.

=head1 SYNOPSIS

  use Solstice::Database;

  my $db = new Solstice::Database()

  # For a read only query that can be sent to any read only servers
  # that are syncronized, or the write master otherwise.
  $db->readQuery("SELECT fname, lname FROM solstice.Person WHERE person_id=?", 15);

  while (my $data_ref = $db->fetchRow()) {
    warn "First: ".$data_ref->{'fname'};
    warn "Last:".$data_ref->{'lname'};
  }

  # For any inserts/updates/deletes, that
  # must go to the master
  $db->writeQuery("INSERT INTO solstice.Person (fname, lname) VALUES (?, ?)", 'Patrick', 'Michaud');

  # Get the id of that person
  my $id = $db->getLastInsertID();

  # Get a read lock (that is, lock other people from reading)
  $db->readLock('solstice.Person');

  # Get a write lock (that is, lock other people from writing)
  $db->writeLock('solstice.Person');

  # Unlock any locks
  $db->unlockTable('solstice.Person');

=head1 DESCRIPTION

This object is here to make the database connections reliable and consistent
across the Solstice tools source tree.  Unlike the most generic methods for
database connectivity, these methods are reliable and efficient in the mod_perl
environment.

**It is strongly recommended that you use this object to make all of your
database connections when programming perl source for the Solstice Tools**

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use DBI;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Solstice::Configure;
use Solstice::Email;
use Solstice::PositionService;
use List::Util qw(shuffle);

use constant SLOW_QUERY_TIME => 10;
use constant FALSE  => 0;
use constant TRUE   => 1;

our ($VERSION) = ('$Revision: 2998 $' =~ /^\$Revision:\s*([\d.]*)/);

our %dbh_cache;
our %dbh_ping_time;
our %slave_dbh_cache;
our %slave_dbh_ping_time;


=head2 Export

No symbols exported.

=head2 Methods

=over 4

=item new()

Constructor. Creates a database handle and caches it.

=cut

sub new {
    my $pkg = shift;

    my $self = $pkg->SUPER::new(@_);
    $self->{'_dbh'} = $self->_connect();

    return $self;
}


=item readQuery($sqlCommand [, $param]*)

For a read only query that can be sent to any read only servers that
are synchronized, or the write master. Dies on error, and returns undef.

=cut

######## TODO: make this work for a cluster #########
sub readQuery {
    my $self = shift;
    my $statement = shift;
    my @params = @_;

    $self->_releaseCursor();

    my $config = $self->getConfigService();
    my $diagnostic = $config->getDevelopmentMode();
    
    #if($diagnostic){
        # we don't really know how handle this and do intellegent diagnostics.
        # we can re-enable this if we figure out something good
        #$self->_diagnostics(join(" ", caller), $statement, @params);
    #}

    my $start_time;
    my $time_taken;
    
    my $dbh = $self->hasSlaves() ? $self->getSlave() : $self->{'_dbh'};

    eval {
        $start_time = [gettimeofday] if $diagnostic;
        my $cursor = $dbh->prepare($statement);
        $cursor->execute(@params);
        $time_taken = tv_interval($start_time, [gettimeofday]) if $diagnostic;
        $self->{'_read_cursor'} = $cursor;
    };
    if ($@) {
        my $error = $@;
        _reportErrorAndDie('readQuery()', $error, join(" ", caller), $statement, \@params);
    }

    if ( $diagnostic &&
        ($time_taken > ($config->getSlowQueryTime() || SLOW_QUERY_TIME)) ) {
        print STDERR "SQL took $time_taken seconds, called from ". join(" ", caller)."\n";
    }
    
    Solstice::PositionService->new()->enqueue('db_read_count');

    return;
}

=item getSlave

Returns the database handle to a slave db.
If there are no slaves, returns the master database handle.

=cut

#XXX Old implementation - remove if the new one works out
#sub getSlave {
#    my $self = shift;
#
#    my $config = $self->getConfigService();
#    my $seen_slaves = {};
#    my $dbh;
#    while(!$self->_isSlaveCurrent($dbh)){
#
#        #check if we've seen all the slaves
#        if(scalar keys %$seen_slaves == scalar @{$config->getDBSlaves()}){
#            $dbh = $self->{'_dbh'};
#            last;
#        }
#
#        my $slave = $config->getDBSlave();
#
#        my $cached_dbh = $slave_dbh_cache{$slave->{'host_name'}};
#        return $cached_dbh if (defined $cached_dbh && $self->_isSlaveCurrent($cached_dbh));
#
#        #if we've seen this slave host try again
#        next if $seen_slaves->{$slave->{'host_name'}};
#
#        $dbh = (defined $cached_dbh) ? $cached_dbh : $self->_connectToSlave($slave);
#
#        #cache away the slaves so we only connect to each slave once
#        $slave_dbh_cache{$slave->{'host_name'}} = $dbh;
#        
#        $seen_slaves->{$slave->{'host_name'}} = TRUE;
#    }
#
#    return $dbh;
#}

sub getSlave {
    my $self = shift;

    my $config = $self->getConfigService();
    my @slaves = shuffle(@{$config->getDBSlaves()});

    for my $slave (@slaves){
        my $hostname = $slave->{'host_name'};

        my $dbh = $slave_dbh_cache{$$}{$hostname};

        if( $dbh && $slave_dbh_ping_time{$$}{$hostname} != time){
            $dbh = undef unless $dbh->ping();
            $slave_dbh_ping_time{$$}{$hostname} = time;
        }

        unless($dbh){
            $dbh = $self->_connectToSlave($slave);
            next unless $dbh;
            $slave_dbh_cache{$$}{$hostname} = $dbh;
            $slave_dbh_ping_time{$$}{$hostname} = time;
        }

        if($self->_isSlaveCurrent($dbh)){
            warn "returnign a slave!";
            return $dbh;
        }
    }

    #oops, none of the slaves worked out
    return $self->{'_dbh'};
}

=item hasSlaves

Returns a count of slaves available for connecting.

=cut

sub hasSlaves {
    my $self = shift;
    return scalar @{$self->getConfigService()->getDBSlaves()};
}

=item fetchRow()

After a read query, fetches a row of results.  Returns undef when
there aren't any more rows to read, otherwise returns a hash ref.

=cut

sub fetchRow {
    my $self = shift;

    return undef if !defined $self->{'_read_cursor'};

    my $row = $self->{'_read_cursor'}->fetchrow_hashref();
    if (!$row) {
        $self->{'_read_cursor'}->finish();
        delete $self->{'_read_cursor'};
    }
    return $row;
}


=item rowCount()

Return a count of rows returned by the last read query, or undef
if a read cursor is not defined.

=cut

sub rowCount {
    my $self = shift;

    return undef if !defined $self->{'_read_cursor'};
    return $self->{'_read_cursor'}->rows();
}


=item writeQuery($sql_command [, $param]*)

For any inserts/updates/deletes that must go to the master.
Dies on error, and returns undef.

=cut

######## TODO: make this work for a cluster #########
sub writeQuery {
    my $self = shift;
    my $statement = shift;
    my @params = @_;

    $self->_releaseCursor();

    my $config = $self->getConfigService();
    my $diagnostic = $config->getDevelopmentMode();

    my $start_time;
    my $time_taken;

    eval {
        $start_time = [gettimeofday] if $diagnostic;
        my $sth = $self->{'_dbh'}->prepare($statement);
        $sth->execute(@params);
        $self->{'_last_insert_id'} = $sth->{'mysql_insertid'};
        $time_taken = tv_interval($start_time, [gettimeofday]) if $diagnostic;
        $self->{'_read_cursor'} = $sth;
    };
    if ($@) {
        my $error = $@;
        _reportErrorAndDie('writeQuery()', $error, join(" ", caller), $statement, \@params);
    }

    if ( $diagnostic &&
        ($time_taken > ($config->getSlowQueryTime() || SLOW_QUERY_TIME)) ) {
        print STDERR "SQL took $time_taken seconds, called from ". join(" ", caller)."\n";
    }
   
    Solstice::PositionService->new()->enqueue('db_write_count');

    return;
}


=item getLastInsertID()

Gets the id of the most recently inserted row.

=cut

sub getLastInsertID {
    my $self = shift;
    return $self->{'_last_insert_id'};
}


=item readLock($table_name)

Gets a read lock (lock other people from reading).
Dies on error, and returns undef.

=cut

sub readLock {
    my $self = shift;
    my $table_name = shift;

    $self->_releaseCursor();

    my $statement = "LOCK TABLES $table_name READ";
    unless ($self->{'_dbh'}->do($statement)) {
        _reportErrorAndDie('readLock()', $self->{'_dbh'}->errstr, join(" ", caller), $statement);
    }
    return;
}


=item writeLock($table_name)

Gets a write lock (lock other people from writing or reading).
Dies on error, and returns undef.

=cut

sub writeLock {
    my $self = shift;
    my $table_name = shift;
    
    $self->_releaseCursor();

    my $statement = "LOCK TABLES $table_name WRITE";
    unless ($self->{'_dbh'}->do($statement)) {
        _reportErrorAndDie('writeLock()', $self->{'_dbh'}->errstr, join(" ", caller), $statement);
    }
    return;
}


=item unlockTables()

Release any table locks. Dies on error, and returns undef.

=cut

sub unlockTables {
    my $self = shift;
    
    $self->_releaseCursor();

    my $statement = 'UNLOCK TABLES';
    unless ($self->{'_dbh'}->do($statement)) {
        _reportErrorAndDie('unlockTable()', $self->{'_dbh'}->errstr, join(" ", caller), $statement);
    }
    return;
}


=item DESTROY()

Destructor.

=cut

sub DESTROY {
    my $self = shift;
    $self->_releaseCursor();
}


=back

=head2 Private methods

=over 4

=cut

=item _isSlaveCurrent($dbh)

Takes a database handle and returns true or false if it is caught up with the master

=cut

sub _isSlaveCurrent {
    my $self = shift;
    my $dbh = shift;
    return FALSE unless defined $dbh;

    my $cursor = $dbh->prepare('SHOW SLAVE STATUS');
    $cursor->execute();
    $self->{'_read_cursor'} = $cursor;

    my $data = $self->fetchRow();
    $self->_releaseCursor();
    
    return FALSE unless $data;
    
    return ($data->{'Seconds_Behind_Master'} eq '0');
}

=item _releaseCursor()

Releases the statement handle that was used for reading.

=cut

sub _releaseCursor {
    my $self = shift;
    if ($self->{'_read_cursor'}) {
        $self->{'_read_cursor'}->finish();
        delete $self->{'_read_cursor'};
    }
}


=item _connect()

Opens and returns the database handle.

=cut

sub _connect {
    my $self = shift;

    if (defined $dbh_cache{$$}){
        if($dbh_ping_time{$$} == time){
            return $dbh_cache{$$};
        }else{
            if( $dbh_cache{$$}->ping()) {
                $dbh_ping_time{$$} = time;
                return $dbh_cache{$$};
            }
        }
    }

    # get the configuration information
    my $config = $self->getConfigService();
    my $host = $config->getDBHost();
    my $port = $config->getDBPort();
    my $user = $config->getDBUser();
    my $password = $config->getDBPassword();
    my $name = $config->getDBName();
    my $connection_string = "DBI:mysql:$name:$host:$port";

    # attempt to connect
    my $dbh = DBI->connect($connection_string, $user, $password,
                           {RaiseError => TRUE});
    if (!$dbh) {
        _reportErrorAndDie('_connect()', "DBI->connect failed: ".$DBI::errstr, join(" ", caller), 'n/a');
    }

    $dbh_cache{$$} = $dbh;
    $dbh_ping_time{$$} = time;
    return $dbh;
}

=item _connectToSlave(\%slave_params)

=cut

sub _connectToSlave {
    my $self = shift;
    my $slave_info = shift;

    #return master if no slaves have been specified
    return $self->_connect() if !defined $slave_info;

    my $host = $slave_info->{'host_name'};
    my $port = $slave_info->{'port'};
    my $user = $slave_info->{'user'};
    my $password = $slave_info->{'password'};
    my $name = $slave_info->{'database_name'};
    my $connection_string = "DBI:mysql:$name:$host:$port";

    # attempt to connect
    my $dbh = DBI->connect($connection_string, $user, $password,
                                   {RaiseError => TRUE});

    return $dbh;
}

=back

=head2 Private functions

=over 4

=cut

=item _reportErrorAndDie($function, $error, $caller, $sql)

Sends an email to the admin, and dies.

=cut

sub _reportErrorAndDie {
    my ($function, $error, $caller, $sql, $params) = @_;

    my $param_string = Dumper $params;

    my $config = Solstice::Configure->new();

    my $mail = Solstice::Email->new();
    $mail->to($config->getAdminEmail());
    $mail->from($config->getServerString().' <'.$config->getAdminEmail().'>');
    $mail->subject("Solstice Tools SQL Error");
    $mail->plainTextBody(
        "The following error string was caught in '$function':\n$error\n\n".
        "The caller was:\n$caller\n\n".
        "The SQL statement that was being executed was:\n$sql\n\n".
        "With params:\n$param_string\n\n"
    );
    $mail->send();

    die "SQL Error: $error\n\nCall stack: $caller\n";
}

#Not in use currently
sub _diagnostics {
    my $self = shift;
    my $caller = shift;
    my $statement = shift;
    my @params = @_;

    eval {
        my $cursor = $self->{'_dbh'}->prepare("EXPLAIN $statement");
        $cursor->execute(@params);

        while( my $row = $cursor->fetchrow_hashref() ){
            unless ($row->{'key'}){
                print STDERR "SQL not using index called from $caller\n";
                last;
            }
        }
    };

    warn "Development Mode SQL diagnostics died\n" if $@;
}


1;

__END__

=back

=head2 Modules Used

L<DBI|DBI>,
L<Date::Dumper|Data::Dumper>,
L<Time::HiRes|Time::HiRes>,
L<Solstice::Configure|Solstice::Configure>,
L<Solstice::Email|Solstice::Email>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2998 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
