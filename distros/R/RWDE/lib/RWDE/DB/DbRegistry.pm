## @file
# (Enter your file info here)
#
# $Id: DbRegistry.pm 496 2008-08-20 14:18:09Z damjan $

# Database connection and handling registry

## @class RWDE::DB::DbRegistry
# Database registry which provides the underlying access API for RWDE objects. Once instantiated and initialized the registry
# provides a one stop shop for managing database connections (open/close), connection setting modifications and
# transaction management (begin/prepare/commit/abort)
package RWDE::DB::DbRegistry;

use strict;
use warnings;

use DBI;
use Error qw(:try);

use RWDE::Configuration;
use RWDE::Exceptions;
use RWDE::RObject;

use base qw(RWDE::Singleton);

our (%dbh, %prepared_transactions, $transaction_connection, $transaction_sequence, $DB_CONFIG, $DB_CONNECTIONS, $impose_transaction);
our ($unique_instance);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 561 $ =~ /(\d+)/;

## @method object get_instance()
# Retrieve the registry instance
# @return retrieved registry instance
sub get_instance {
  my ($self, $params) = @_;

  if (ref $unique_instance ne $self) {
    $unique_instance = $self->new;
  }

  return $unique_instance;
}

## @method void initialize()
# Read the configuration file for DB names and locations
# these data are used for opening connections
sub initialize {
  my ($self, $params) = @_;

  # initialize the params for connecting to the db
  $DB_CONFIG = RWDE::Configuration->DB;

  # and mapping between the db names and connections
  $DB_CONNECTIONS = RWDE::Configuration->DB_CONNECTIONS;

  $transaction_sequence = 0;

  $impose_transaction = undef;
  
  return ();
}

## @method object get_dbh()
# Retrieve the database handle for a specific database name. In the event that a transaction was
# previously signalled the transaction will begin here
# &param db Database name
# @return The database handle for a specific database
sub get_dbh {
  my ($self, $params) = @_;

  my $connection_name = $self->_get_connection_name($params);

  unless (defined $dbh{$connection_name} and $dbh{$connection_name}->ping()) {
    $self->_connect_db({ connection => $connection_name });
  }

  #we have received an earlier signal to start a transaction and it hasn't completed yet
  if (transaction_signalled()) {

    #if there is no transaction defined yet
    if (!defined($transaction_connection)) {

      $self->_begin_transaction($params);
    }
  }

  return $dbh{$connection_name};
}

## @method void add_db_settings($db_settings)
# Pass a setting to the database. This needs to be set before the connection is established
# @param db_settings  Specific setting to be applied to the database at connect time
sub add_db_settings {
  my ($self, $params) = @_;

  my $db_setting_param = $$params{db_settings};

  if (not defined($db_setting_param) || ref($db_setting_param) ne "ARRAY") {
    throw RWDE::DevelException({ info => "DB setting supplied undefined or not an array" });    
  }

  my $connection_name = RWDE::DB::DbRegistry->_get_connection_name($params);
  
  push (@{$$DB_CONFIG{$connection_name}{db_settings}}, @$db_setting_param);

  return ();
}

## @method object get_db_notifications($sleeptime)
# Retrieve notifications (pg_notifies) from the database
# &param db The database name that you want notifications for
# @param sleeptime  Length of time to block while waiting for notifications
# @return Array reference of notifications the db raised
sub get_db_notifications {
  my ($self, $params) = @_;

  my $dbh = $self->get_dbh($params);

  my @required = qw( sleeptime );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  use IO::Select;

  my @notifications;
  my $dbpid  = $dbh->{pg_pid};
  my $dbsock = $dbh->{pg_socket};

  my $select = new IO::Select($dbsock)
    or throw RWDE::DevelException({ info => "Failed to create selector" });

  if (my @ready = $select->can_read($$params{sleeptime})) {
    while (my $notification = $dbh->func('pg_notifies')) {
      push(@notifications, $notification);    # "got NOTIFY $n->[0] from $n->[1]";
    }
  }

  return \@notifications;
}

## @method void destroy_dbh()
# Tear down and clear (from the registry) the database associated with the database parameter it was invoked with
# param db The database name you want to destroy the handle for
sub destroy_dbh {
  my ($self, $params) = @_;

  my $connection_name = $self->_get_connection_name($params);

  $dbh{$connection_name}->{InactiveDestroy} = 1;

  $self->closeDB($params);

  return;
}

## @method void closeDB()
# Close a specific database handle and the delete referenced db from the registry
# -
# Note: Don't do explicit disconnect if we're a child process clearing out the old handle just prior to re-opening it.
# In this case, we set InactiveDestroy to keep DBI from doing the implicit disconnect when the handle goes away.
sub closeDB {
  my ($self, $params) = @_;

  my $connection_name = $self->_get_connection_name($params);

  if ($dbh{$connection_name} and !$dbh{$connection_name}->{InactiveDestroy}) {
    $dbh{$connection_name}->disconnect;
  }

  delete $dbh{$connection_name};

  return ();
}

## @method void close_all()
# Close all database connections we are currently maintaining
sub close_all {
  my ($self, $params) = @_;

  foreach my $connection_name (keys %$DB_CONNECTIONS) {
    if ($dbh{$connection_name} and !$dbh{$connection_name}->{InactiveDestroy}) {
      $dbh{$connection_name}->disconnect;
    }

    delete $dbh{$connection_name};
  }

  return ();
}

## @method void close_all()
# Release the handles w/o explicitly disconnecting: i.e. on fork
sub destroy_all {
  my ($self, $params) = @_;

  foreach my $db_name (keys %$DB_CONNECTIONS) {
    $self->destroy_dbh({ db => $db_name});
  }

  return ();
}

#================================================================
#everything below is transaction related - global can call these
#================================================================

## @method void signal_transaction()
# Signal the database backend to begin a transaction before the next database operation takes place
sub signal_transaction {
  my ($self, $params) = @_;

  #if this flag is already set and we ended up here something is wrong
  if (!transaction_signalled()) {
    $impose_transaction = 1;
  }
  else {
    warn 'Received a signal for impose transaction, but transaction already in progress';
  }

  return ();
}

## @method object transaction_signalled()
# Determine if a transaction has been signalled in the backend
# @return true if a transaction is signalled, false otherwise
sub transaction_signalled {
  my ($self, $params) = @_;

  return (defined($impose_transaction));
}

## @method void commit_transaction()
# Commit the running transaction within the database. Will invoke an exception if a transaction
# is not currently defined or if the transaction does not execute properly. After committing a
# transaction the related state variables are cleared.
sub commit_transaction {
  my ($self, $params) = @_;

  if (!(defined $transaction_connection and $dbh{$transaction_connection} and $dbh{$transaction_connection}->commit())) {
    warn "Commit transaction called with no outstanding transaction -> probably aborted before";
  }

  $transaction_connection = undef;

  $impose_transaction = undef;

  return ();
}

## @method void abort_transaction()
# Abort the running transaction within the database. If no transaction is running then this operation
# acts as a no-op
sub abort_transaction {
  my ($self, $params) = @_;

  if (defined($transaction_connection)) {
    $dbh{$transaction_connection}->rollback();
    $transaction_connection = undef;
  }

  $impose_transaction = undef;

  return ();
}

## @method object prepare_transaction()
# Prepare and save the currently running transaction within the database. An exception will be thrown if
# no transaction is running or there is a problem preparing the transaction. Once the transaction is prepared a
# string handle/reference is returned back to the caller to allow for processing of the transaction at a later time
# @return string handle/reference to the prepared transaction
sub prepare_transaction {
  my ($self, $params) = @_;

  $self->check_transaction();

  my $transaction_name = $self->_get_transaction_name($params);

  #unfortunately DBI does not have a call to support 2pc yet
  my $sth = $dbh{$transaction_connection}->prepare("PREPARE TRANSACTION ?");

  if (!($sth && $sth->execute($transaction_name))) {
    throw RWDE::DevelException({ info => $dbh{$transaction_connection}->errstr() });
  }

  #store the transaction connection name associated with this prepared transaction
  $prepared_transactions{$transaction_name} = $transaction_connection;

  #clear out transaction connection
  $transaction_connection = undef;

  $impose_transaction = undef;

  return $transaction_name;
}

## @method void commit_prepared_transaction($transaction_name)
# Commit a previously prepared transaction within the database. An exception will be thrown if
# the transaction doesn't exist or if there is a problem committing the transaction.
# @param transaction_name  Handle/reference to a previously prepared transaction
sub commit_prepared_transaction {
  my ($self, $params) = @_;

  #if the transaction is not defined then something is wrong
  if (!defined($$params{transaction_name})) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "Attempt to commit an unspecified prepared transaction without a name: $package on $line" });
  }

  my $transaction_name = $$params{transaction_name};
  my $connection       = $prepared_transactions{$transaction_name};

  if (not defined $connection){
      $connection = $self->_get_connection_name($params);
  }

  if (defined($connection) && defined($transaction_name)) {

    #unfortunately DBI does not have a call to support 2pc yet
    if (!defined($dbh{$connection}->do("COMMIT PREPARED " . $dbh{$connection}->quote($transaction_name)))) {
      throw RWDE::DevelException({ info => $dbh{$connection}->errstr() });
    }
  }

  #clear out transaction
  $prepared_transactions{$transaction_name} = undef;

  return ();
}

## @method void abort_prepared_transaction($transaction_name)
# Abort a previously prepared transaction within the database. An exception will be thrown if
# the transaction doesn't exist or if there is a problem committing the transaction.
# @param transaction_name  Handle/reference to a previously prepared transaction
sub abort_prepared_transaction {
  my ($self, $params) = @_;

  #if the transaction is not defined then something is wrong
  if (!defined($$params{transaction_name})) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "Attempt to commit an unspecified prepared transaction without a name: $package on $line" });
  }

  my $transaction_name = $$params{transaction_name};
  my $connection       = $prepared_transactions{$transaction_name};

  if (not defined $connection){
      $connection = $self->_get_connection_name($params);
  }

  if (defined($connection) && defined($transaction_name)) {

    #unfortunately DBI does not have a call to support 2pc yet
    if (!defined($dbh{$connection}->do("ROLLBACK PREPARED " . $dbh{$connection}->quote($transaction_name)))) {
      throw RWDE::DevelException({ info => $dbh{$connection}->errstr() });
    }
  }
  else {
    warn 'Either connection or transaction_name not defined';
  }

  #clear out transaction
  $prepared_transactions{$transaction_name} = undef;

  return ();
}

## @method void check_transaction()
# Test to see if we have a transaction and that everything is consistent. Throw a devel exception if no
# transaction is running.
# -
# This is used to ensure that we are in ANY transaction - regardless of connection. Maybe this is bad
sub check_transaction {
  my ($self, $params) = @_;

  if (!defined($transaction_connection) || !defined($dbh{$transaction_connection}) || !transaction_signalled()) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "Attempt to get transaction name for nonexistent transaction:  $package on $line" });
  }

  return ();
}

## @method object has_transaction()
# Determine if the argument db connection has a transaction
# &param db name of the database supposedly in a transaction
# @return true if the database is in a transaction, false otherwise
sub has_transaction {
  my ($self, $params) = @_;

  #check to see if a transaction is signalled and if the argument connection is associated with such a signalled transaction
  return (transaction_signalled() && defined($transaction_connection) && ($transaction_connection eq $self->_get_connection_name($params)));
}

## @method void db_check_transaction()
# Determine if the current transaction is associated with the specified db param - otherwise devel exception
sub db_check_transaction {
  my ($self, $params) = @_;

  unless (has_transaction($params)) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "$package on $line requires exclusive access to the affecting rows. Add transaction around the function call." });
  }

  return ();
}

## @method void cleanup()
# Cleanup running transactions on all connections by aborting them
sub cleanup {
  my ($self, $params) = @_;

  foreach my $db (keys %dbh) {
    if (defined($transaction_connection)) {
      $self->abort_transaction();
    }
    $dbh{$db}->do("RESET ALL");    # unset any special variables
  }

  return ();
}

#================================================================
#everything below is private - do not call externally
#================================================================

## @method protected object _get_connection_name($db)
# Private call to determine the connection name for a database name argument
# @param db  Database name you are seeking the connection name for
# @return the connection name associated with the database name argument
sub _get_connection_name {
  my ($self, $params) = @_;

  my $label = $$params{db};

  if (not defined $label) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "DB not specified: $package on $line" });
  }

  my $connection_name = $$DB_CONNECTIONS{$label};

  if (!defined($connection_name)) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(2);
    throw RWDE::DevelException({ info => "No connection specified for given db:$label: from $package on $line" });
  }

  return $connection_name;
}

sub get_host {
  my ($self, $params) = @_;

  my $connection_name = $self->_get_connection_name({ db => $$params{db}});

  my $DB = $$DB_CONFIG{$connection_name};

  return $$DB{db_host};
}


## @method protected void _connect_db($connection)
# Create a database connection for the connection_name argument given. If there are any problems an exception will be thrown.
# Upon success the database connection handle is added to the registry and may be retrieved using "get_dbh".
# @param connection  The connection_name you are trying to create a connection for
sub _connect_db {
  my ($self, $params) = @_;

  my $connection_name = $$params{connection};

  my $DB         = $$DB_CONFIG{$connection_name};
  my $port       = $$DB{db_port} ? $$DB{db_port} : 5432;
  my $datasource = 'dbi:' . $$DB{db_type} . ':dbname=' . $$DB{db_name} . ';host=' . $$DB{db_host} . ';port=' . $port;

  if (RWDE::Configuration->Debug) {

    #disable preparing of queries so we can see them
    $dbh{$connection_name} = DBI->connect($datasource, $$DB{db_user}, $$DB{db_pass}, { PrintError => 0, pg_server_prepare => 0 })
      or throw RWDE::DevelException({ info => "dbi connect failure: " . $DBI::errstr });
  }
  else {
    #tmp fix, put prepare to 0, looks like pg_bouncer is not liking it a lot
    $dbh{$connection_name} = DBI->connect($datasource, $$DB{db_user}, $$DB{db_pass}, { PrintError => 0, pg_server_prepare => 0 })
      or throw RWDE::DevelException({ info => "dbi connect failure: " . $DBI::errstr });
  }

  # and listen for events to wake us up
  foreach my $db_setting (@{$$DB{db_settings}}) {
    $dbh{$connection_name}->do($db_setting)
      or throw RWDE::DevelException({ info => "failed to set: $db_setting for $connection_name" });
  }

  return ();
}

## @method protected object _get_transaction_name()
# This method provides a uniq naming scheme for naming prepared transactions.
# @return Unique name that is suitable to be used for preparing a transaction
sub _get_transaction_name {
  my ($self, $params) = @_;

  $self->check_transaction();

  my $dbh = $dbh{$transaction_connection};

  my $transaction_name = $$ . "|" . $dbh->{pg_pid} . "|" . $transaction_sequence;

  $transaction_sequence++;

  return $transaction_name;
}

## @method protected void _begin_transaction()
# Private method to begin a transaction. The only appropriate place to use it within this registry construct
# is immediately after a transaction signal has been raised - but before any other database queries are executed.
sub _begin_transaction {
  my ($self, $params) = @_;

  #if there are ANY other transactions then something is wrong
  if (defined($transaction_connection)) {
    throw RWDE::DevelException({ info => "Attempt to start multiple transactions" });
  }

  my $connection_name = $self->_get_connection_name($params);

  $transaction_connection = $connection_name;

  if (!($dbh{$connection_name})) {
    throw RWDE::DevelException({ info => 'Error while attempting to _begin_transaction -- no connection_name' });
  }

  if (!($dbh{$connection_name}->begin_work())) {
    throw RWDE::DevelException({ info => 'Error while attempting to _begin_transaction failed: ' . $dbh{$connection_name}->errstr() });
  }

  return ();
}

1;
