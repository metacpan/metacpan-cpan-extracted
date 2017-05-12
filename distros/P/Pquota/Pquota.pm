#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Pquota.pm                                                                   #
#                                                                              #
#  written by david bonner and scott savarese                                  #
#  dbonner@cs.bu.edu                                                           #
#  savarese@cs.bu.edu                                                          #
#  theft is treason, citizen                                                   #
#                                                                              #
#  copyright(c) 1999 david bonner, scott savarese.  all rights reserved.       #
#  this program is free software; you can redistribute and/or modify it        #
#  under the same terms as perl itself                                         #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Pquota;

# make CPAN happy
$Pquota::VERSION = 1.1;

use Fcntl;
use MLDBM;
use Carp;
use strict;

# constant for unlimited printer use
sub UNLIMITED { return 23000000; }


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#                                 object methods                               #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


##  object creation
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  bless $self, $class;
  $self->_init(@_);

  return $self;
}


##  close the objct by untie'ing the hashes
sub close {
  my $self = shift;

  # loop through and close all tied dbms
  for (keys %{$self->{'dbms'}}) {
    untie %{$self->{'dbms'}{$_}};
  }

  return 1;
}


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#                           printer database commands                          #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


##  adds a printer to the printers dbm
sub printer_add {
  my ($self, $printer, $cost, $dbm) = @_;
  my $entry = {};

  # sanity check
  unless ($printer && defined($cost) && $dbm) {
    carp "Invocation:  \$pquota->printer_add (\$printer, \$page_cost, \$user_db)";
    return undef;
  }

  # initialize the hash values
  $entry->{'cost'} = $cost;
  $entry->{'dbm'} = $dbm;

  # get the lock
  $self->_get_lock ('_printers');

  # store it in the hash
  $self->{'dbms'}{'_printers'}{$printer} = $entry;

  # release the lock
  $self->_release_lock ('_printers');

  return 1;
}


##  removes a printer from the printers dbm
sub printer_rm {
  my ($self, $printer) = @_;

  # sanity check on the arg passed in
  unless ($printer) {
    carp "Invocation:  \$pquota->printer_rm (\$printer)";
    return undef;
  }

  # check to see if it was there in the first place
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_rm:  $printer not in the _printers database";
    return undef;
  }

  # get the lock
  $self->_get_lock ('_printers');

  # remove the printer from the dbm
  delete ($self->{'dbms'}{'_printers'}{$printer});

  # release the lock
  $self->_release_lock ('_printers');

  return 1;
}


##  changes the cost per page of the printer
sub printer_set_cost {
  my ($self, $printer, $cost) = @_;
  my $entry;

  # sanity check
  unless ($printer && defined($cost)) {
    carp "Invocation:  \$pquota->printer_set_cost (\$printer, \$cost)";
    return undef;
  }

  # make sure the printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_set_cost:  $printer not in _printers database";
  }

  # get the entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};
  
  # get the lock
  $self->_get_lock ('_printers');

  # change the value
  $entry->{'cost'} = $cost;
  $self->{'dbms'}{'_printers'}{$printer} = $entry;

  # release the lock
  $self->_release_lock ('_printers');

  return 1;
}


##  returns the cost per page of the printer
sub printer_get_cost {
  my ($self, $printer) = @_;
  my $entry;

  # sanity check
  unless ($printer) {
    carp "Invocation:  \$pquota->printer_get_cost (\$printer)";
    return undef;
  }

  # make sure the printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_get_cost:  $printer not in _printers database";
    return undef;
  }

  # get printer entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};

  # return the cost
  return $entry->{'cost'};
}


##  list all the printers and their per-page cost
sub printer_get_cost_list {
  my $self = shift;
  my $ref = {};
  my $entry;

  # loop through printer hash, store costs in $ref
  for (keys (%{$self->{'dbms'}{'_printers'}})) {
    $entry = $self->{'dbms'}{'_printers'}{$_};
    $ref->{$_} = $entry->{'cost'};
  }

  return $ref;
}


##  set the user database that a printer uses
sub printer_set_user_database {
  my ($self, $printer, $dbm) = @_;
  my $entry;

  # sanity check
  unless ($printer && $dbm) {
    carp "Invocation:  \$pquota->printer_set_user_database (\$printer, \$database)";
    return undef;
  }

  # make sure printer is in database
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_set_user_database:  $printer not in _printers database";
    return undef;
  }

  # get printer entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};

  # get file lock
  $self->_get_lock ('_printers');

  # set the dbm field
  $entry->{'dbm'} = $dbm;
  $self->{'dbms'}{'_printers'}{$printer} = $entry;

  # release file lock
  $self->_release_lock ('_printers');

  return 1;
}


##  gets the user database for a printer
sub printer_get_user_database {
  my ($self, $printer) = @_;
  my $entry;

  # sanity check
  unless ($printer) {
    carp "Invocation:  \$pquota->printer_get_user_database (\$printer)";
    return undef;
  }

  # make sure printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_get_user_database:  $printer not in _printers database";
    return undef;
  }

  # get printer entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};

  # return the user database
  return $entry->{'dbm'};
}


##  list all the printers and the user databases they use
sub printer_get_user_database_list {
  my $self = shift;
  my $ref = {};
  my $entry;

  # loop through printer hash, store dbms in $ref
  for (keys (%{$self->{'dbms'}{'_printers'}})) {
    $entry = $self->{'dbms'}{'_printers'}{$_};
    $ref->{$_} = $entry->{'dbm'};
  }

  return $ref;
}


##  set an arbitrary field in a printer entry
sub printer_set_field {
  my ($self, $printer, $key, $val) = @_;
  my $entry;

  # sanity check, allow for empty value, but not an undefined one
  unless ($printer && $key && defined ($val)) {
    carp "Invocation:  \$pquota->printer_set_field (\$printer, \$key, \$value)";
    return undef;
  }

  # make sure printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_set_field:  $printer not in _printers database";
    return undef;
  }

  # get the printer entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};

  # get file lock
  $self->_get_lock ('_printers');

  # set the field
  $entry->{$key} = $val;
  $self->{'dbms'}{'_printers'}{$printer} = $entry;

  # release file lock
  $self->_release_lock ('_printers');

  return 1;
}


##  get an arbitrary field in a printer entry
sub printer_get_field {
  my ($self, $printer, $key);
  my $entry;

  # sanity check
  unless ($printer && $key) {
    carp "Invocation:  \$pquota->printer_get_field (\$printer, \$key)";
    return undef;
  }

  # make sure printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::printer_get_field:  $printer not in _printers database";
    return undef;
  }

  # get the printer entry
  $entry = $self->{'dbms'}{'_printers'}{$printer};

  # return the field
  return $entry->{$key};
}


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#                              user database methods                           #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


##  add user to a user dbm
sub user_add {
  my ($self, $user, $dbm, $periodic) = @_;
  my $entry = {};

  # sanity check
  unless ($dbm && $user && defined($periodic)) {
    carp "Invocation:  \$pquota->user_add (\$user, \$database, \$periodic)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure they don't already have an entry
  if (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_add:  $user already exists in the users database";
    return undef;
  }

  # set the default values for this user
  if ($periodic eq 'unlimited') {
    $periodic = UNLIMITED();
  }
  $entry->{'periodic'} = $periodic;
  $entry->{'current'} = $periodic;
  $entry->{'total'} = 0;


  # get the lock file
  $self->_get_lock ($dbm);

  # store it in the hash
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock file
  $self->_release_lock ($dbm);
  
  return 1;
}


##  remove a user from a user database
sub user_rm {
  my ($self, $user, $dbm) = @_;
  
  # sanity check
  unless ($dbm && $user) {
    carp "Invocation:  \$pquota->user_rm (\$user, \$database)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_rm:  $user not in $dbm database";
    return undef;
  }

  # get the lock
  $self->_get_lock ($dbm);
  
  # remove the user
  delete ($self->{'dbms'}{$dbm}{$user});

  # relese the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  mark the appropriate amount as having been printed
sub user_print_pages {
  my ($self, $user, $printer, $pages) = @_;
  my ($user_entry, $printer_entry, $cost);
  my $err = 0;

  # make sure we were called correctly
  unless ($user && $printer && defined($pages)) {
    carp "Invocation:  \$pquota->user_print_pages (\$user, \$printer, \$pages)";
    return undef;
  }

  # make sure printer exists
  unless (defined ($self->{'dbms'}{'_printers'}{$printer})) {
    carp "Pquota::user_print_pages:  $printer not in _printers database";
    return undef;
  }
  $printer_entry = $self->{'dbms'}{'_printers'}{$printer};

  # make sure the user dbm is open
  unless ($self->_open_dbm ($printer_entry->{'dbm'})) {
    carp "Pquota::user_print_pages:  Unable to open user database $printer_entry->{'dbm'}";
    return undef;
  }

  # make sure user exists
  unless (defined ($self->{'dbms'}{$printer_entry->{'dbm'}}{$user})) {
    carp "Pquota::user_print_pages:  $user not in $printer_entry->{'dbm'} database";
    return undef;
  }
 
  # get the lock
  $self->_get_lock ($printer_entry->{'dbm'});

  # mark off the appropriate amount
  $user_entry = $self->{'dbms'}{$printer_entry->{'dbm'}}{$user};
  $cost = $printer_entry->{'cost'} * $pages;

  # catch the over quota problem
  if ($user_entry->{'current'} < $cost) {
    carp "Pquota::user_print_pages:  $user over quota";
    $user_entry->{'current'} = 0;
    $user_entry->{'total'} += $cost;
    $self->{'dbms'}{$printer_entry->{'dbm'}}{$user} = $user_entry;
    $self->_release_lock ($printer_entry->{'dbm'});
    return undef;
  }
  
  # update the values  
  $user_entry->{'current'} -= $cost;
  $user_entry->{'total'} += $cost;

  # store it
  $self->{'dbms'}{$printer_entry->{'dbm'}}{$user} = $user_entry;

  # release the lock
  $self->_release_lock ($printer_entry->{'dbm'});

  return 1;
}


##  adds to user's current quota
sub user_add_to_current {
  my ($self, $user, $dbm, $amt) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user && defined($amt)) {
    carp "Invocation:  \$pquota->user_add_to_current (\$user, \$database, \$amount)";
    return undef;
  }

  # make sure dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # check for user in users database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_add_to_current:  $user not in users database";
    return undef;
  }

  # get the lock
  $self->_get_lock ($dbm);

  # get user entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # modify the current field
  $entry->{'current'} += $amt;

  # store the entry 
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  sets a new current value for a user
sub user_set_current {
  my ($self, $user, $dbm, $amt) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user && defined($amt)) {
    carp "Invocation:  \$pquota->user_set_current (\$user, \$database, \$amount)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_set_current:  $user not in users database";
    return undef;
  }

  # get the user entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # set the new value, reset the current value
  if ($amt eq 'unlimited') {
    $amt = UNLIMITED;
  }
  $entry->{'current'} = $amt;

  # get the lock
  $self->_get_lock ($dbm);

  # store the entry
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  checks for the current quota of a specified user
sub user_get_current_by_dbm {
  my ($self, $user, $dbm) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user) {
    carp "Invocation:  \$pquota->user_get_current_by_dbm (\$user, \$database)";
    return undef;
  }

  # make sure user dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure user is in database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_get_current_by_dbm:  $user not in $dbm database";
    return undef;
  }

  # get entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  return $entry->{'current'};
}


##  checks for the current quota of a specified user
sub user_get_current_by_printer {
  my ($self, $user, $printer) = @_;
  my ($entry, $dbm);

  # sanity check
  unless ($printer && $user) {
    carp "Invocation:  \$pquota->user_get_current_by_printer (\$user, \$printer)";
    return undef;
  }

  # find out which user database to use
  unless ($dbm = $self->printer_get_user_database ($printer)) {
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm($dbm)) {
    return undef;
  }

  # make sure user is in database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_get_current_by_printer:  $user not in $dbm database";
    return undef;
  }

  # get entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  return $entry->{'current'};
}


##  resets the current value to the periodic value
sub user_reset_current {
  my ($self, $user, $dbm) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user) {
    carp "Invocation:  \$pquota->user_reset current (\$user, \$database)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_reset_current:  $user not in users database";
    return undef;
  }

  # get the user entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # set the new value, reset the current value
  $entry->{'current'} = $entry->{'periodic'};

  # get the lock
  $self->_get_lock ($dbm);

  # store the entry
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}



##  adds to user's periodic quota
sub user_add_to_periodic {
  my ($self, $user, $dbm, $amt) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user && defined($amt)) {
    carp "Invocation:  \$pquota->user_add_to_periodic (\$user, \$user_db, \$amount)";
    return undef;
  }

  # make sure dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # check for user in users database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_add_to_periodic:  $user not in users database";
    return undef;
  }

  # get the lock
  $self->_get_lock ($dbm);

  # get user entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # modify the periodic field
  $entry->{'periodic'} += $amt;

  # store the entry 
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  sets a new quota value for a user
sub user_set_periodic {
  my ($self, $user, $dbm, $amt) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user && defined($amt)) {
    carp "Invocation:  \$pquota->user_set_periodic (\$user, \$database, \$amount)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_set_periodic:  $user not in users database";
    return undef;
  }

  # get the user entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # set the new value
  if ($amt eq 'unlimited') {
    $amt = UNLIMITED;
  }
  $entry->{'periodic'} = $amt;
  $entry->{'current'} = $amt;

  # get the lock
  $self->_get_lock ($dbm);

  # store the entry
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  checks for the periodic quota of a specified user
sub user_get_periodic {
  my ($self, $user, $dbm) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user) {
    carp "Invocation:  \$pquota->user_get_periodic (\$user, \$database)";
    return undef;
  }

  # make sure user dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure user is in database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_get_periodic:  $user not in $dbm database";
    return undef;
  }

  # get entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  return $entry->{'periodic'};
}


##  resets out the total quota
sub user_reset_total {
  my ($self, $user, $dbm) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user) {
    carp "Invocation:  \$pquota->user_reset_total (\$user, \$database)";
    return undef;
  }

  # make sure user dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure user is in database
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_reset_total:  $user not in $dbm database";
    return undef;
  }

  # get entry
  $entry = $self->{'dbms'}{$dbm}{$user};

  # reset the total field
  $entry->{'total'} = 0;
  
  # get the lock
  $self->_get_lock ($dbm);

  # store it
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # give up the lock
  $self->_release_lock ($dbm);
 
  # return
  return 1; 
}


##  set an arbitrary field in a user's record
sub user_set_field {
  my ($self, $user, $dbm, $key, $val) = @_;
  my $entry;

  # sanity check, allow for empty value, but not an undefined one
  unless ($dbm && $user && $key && defined ($val)) {
    carp "Invocation:  \$pquota->user_set_field (\$user, \$database, \$key, \$value)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_set_field:  $user not in $dbm database";
    return undef;
  }

  # get the lock
  $self->_get_lock ($dbm);

  # get the entry, set the value
  $entry = $self->{'dbms'}{$dbm}{$user};
  $entry->{$key} = $val;
  $self->{'dbms'}{$dbm}{$user} = $entry;

  # release the lock
  $self->_release_lock ($dbm);

  return 1;
}


##  get an arbitrary field in a user's record
sub user_get_field {
  my ($self, $user, $dbm, $key) = @_;
  my $entry;

  # sanity check
  unless ($dbm && $user && $key) {
    carp "Invocation:  \$pquota->user_get_field (\$user, \$database, \$key)";
    return undef;
  }

  # make sure the dbm is open
  unless ($self->_open_dbm ($dbm)) {
    return undef;
  }

  # make sure the user exists
  unless (defined ($self->{'dbms'}{$dbm}{$user})) {
    carp "Pquota::user_set_field:  $user not in $dbm database";
    return undef;
  }

  # get the entry, get the value
  $entry = $self->{'dbms'}{$dbm}{$user};

  return $entry->{$key};
}


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#                              private subroutines                             #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


## object initialization
sub _init {
  my ($self, $quotadir, $db_opts) = @_;

  # sanity check on passed argument
  unless (-d $quotadir) {
    croak "Invocation:  Pquota->new (\$quotadir[, \$opts])\n";
  }

  # set the options
  if ($db_opts) {
    if ($db_opts->{'UseDB'}) {
      $MLDBM::UseDB = $db_opts->{'UseDB'};
    }
    if ($db_opts->{'Serializer'}) {
      $MLDBM::Serializer = $db_opts->{'Serializer'};
    }
    if ($db_opts->{'RO'} && ($db_opts->{'RO'} =~ /true/i)) {
      $self->{'RO'} = 1;
    }
  }

  # store the quota directory, tie the _printers hash
  $self->{'quotadir'} = $quotadir;
  $self->{'dbms'} = {};
  $self->_open_dbm ("_printers");

  # now return
  return 1;
}


##  open a dbm file
sub _open_dbm {
  my ($self, $dbm) = @_;
  my $options;

  # return immediately if it already exists
  if (defined ($self->{'dbms'}{$dbm})) {
    return 1;
  }

  # tie the hash
  $self->{'dbms'}->{$dbm} = {};
  $options = ($self->{'RO'}) ? O_RDONLY : O_RDWR|O_CREAT;
  unless (tie (%{$self->{'dbms'}->{$dbm}}, 'MLDBM', "$self->{'quotadir'}/$dbm",
               $options, 0644)) {
    carp "Pquota::_open_dbm:  Unable to open the $dbm database in $self->{'quotadir'}:  $!";
    return 0;
  }

  # now return
  return 1;
}


##  get exclusive access to a lock file before changing the dbm
sub _get_lock {
  my ($self, $dbm) = @_;
  my ($file, $fh);

  # get a file handle to open the lock file
  unless ($fh = eval { local *FH }) {
    croak "Pquota::_get_lock:  Internal error:  $!\n";
  }

  # wait until I get to open the lock file
  $file = "$self->{'quotadir'}/$dbm.lock";
  while (!(sysopen ($fh, $file, O_RDWR|O_CREAT|O_EXCL, 0644))) { }

  # store the file handle so I can close it later
  $self->{"lock"} = $fh;

  return 1;
}


##  close the lock file and remove it from the directory
sub _release_lock {
  my ($self, $dbm) = @_;
  my $file;

  # close the file, then unlink it
  CORE::close ($self->{"lock"});
  $file = "$self->{'quotadir'}/$dbm.lock";
  unlink $file;
  delete $self->{"lock"};

  return 1;
}

1;

###########################  END CODE, BEGIN DOCS  ###########################

=pod

=head1 NAME

Pquota - a UNIX print quota module

=head1 SYNOPSIS

    use Pquota;

    # object creator and destructor
    $pquota = Pquota->new ("/path/to/quota/directory"[, $opts]);
    $pquota->close ();

    # printers database commands
    $pquota->printer_add ($printer, $page_cost, $user_db);
    $pquota->printer_rm ($printer);
    $pquota->printer_set_cost ($printer, $cost);
    $pquota->printer_get_cost ($printer);
    $pquota->printer_get_cost_list ();
    $pquota->printer_set_user_database ($printer, $user_db);
    $pquota->printer_get_user_database ($printer);
    $pquota->printer_get_user_database_list ();
    $pquota->printer_set_field ($printer, $key, $value);
    $pquota->printer_get_field ($printer, $key);

    # user database commands
    $pquota->user_add ($user, $user_db, $periodic_quota);
    $pquota->user_rm ($user, $user_db);
    $pquota->user_print_pages ($user, $printer, $num_pages);
    $pquota->user_add_to_current ($user, $user_db, $amount);
    $pquota->user_set_current ($user, $user_db, $periodic_quota);
    $pquota->user_get_current_by_dbm ($user, $user_db);
    $pquota->user_get_current_by_printer ($user, $printer);
    $pquota->user_reset_current ($user, $user_db);
    $pquota->user_add_to_periodic ($user, $user_db, $amount);
    $pquota->user_set_periodic ($user, $user_db, $amount);
    $pquota->user_get_periodic ($user, $user_db);
    $pquota->user_reset_total ($user, $user_db);
    $pquota->user_set_field ($user, $user_db, $key, $value);
    $pquota->user_get_field ($user, $user_db, $key);

=head1 DESCRIPTION 

This module is an attempt to provide an easy interface to a group
of DBM files used to store print quota information on a UNIX system.
It makes writing printer interface scripts a lot easier.  Pquota
requires the MLDBM module.

As we've said, Pquota is a wrapper module for handling DBM files.  We've
structured it so that there is one database that contains information about
the different printers on your system, and any number of user databases.  The
printers database, which we've named _printers to (hopefully) avoid any
namespace clashes.  An entry in the _printers database looks something like
this:

        $printer_entry = {'cost'        =>      5,
                          'dbm'         =>      'students'};

Every printer has a cost per page, and an associated user database.
Multiple printers can point to the same user database, but you can't
have multiple databases for the same printer.

Pquota is designed with a periodic allotment of quota in mind.  On our
systems, students get a couple dollars worth every week.  So every entry
in a user database looks like this:

        $user_entry = {'periodic'       =>      300,
                       'current'        =>      273,
                       'total'          =>      27      }; 

And once a week, we run a cron job to reset all the current values
to be equal to the periodic values.

Pquota also has pessimistic file locking internal to its DBM accesses,
so there won't be any problems with corrupt DBM files.  However, we
decided not to register any signal handlers to deal with signals when
the files are locked, because we didn't want to be overriding any
handlers in the enclosing program.  Just in case, all of the lock files
are named dbm.lock, where dbm is the name of the DBM that is locked.
They reside in the same directory as the DBMs themselves.


=head2 MLDBM Notes

MLDBM by default uses Data::Dumper to translate Perl data structures into
strings, and SDBM_File to store them to disk.  This is because SDBM_File
comes with all UNIX installs of Perl, and Data::Dumper was originally the
only module which could serialize Perl's data structures.  However, it
also has the option of using any of the other DBM modules for storage,
and either Storable or FreezeThaw to serialize the structures.  As such,
we've added the $opts option to the new method.  Just give it
a hash reference, with the keys 'UseDB' or 'Serializer', to set either
the DBM module or the serializing module, respectively.  For example, 

    $pquota = Pquota->new ("/var/spool/pquota", {'UseDB' => 'DB_File'});

would tell MLDBM to use the DB_File module to store the structures to
disk.

Also, to avoid unnecessary locking, we've added an option to open the
databases in read-only mode, so that scripts that won't be writing to the
databases don't lock it.  Simply set the 'RO' option to 'true' in order
to open the databases in read-only mode.

    $pquota = Pquota->new ("/var/spool/pquota", {'RO' => 'true'});


=head2 Method Notes

All methods return either the requested information or 1 in case of success,
and undef in case of failure.

=head2 Object Methods

=over 4

=item Pquota::new ($quotadir[, $opts])

Standard object constructor.  $quotadir should contain the path to
a directory to store the DBMs.  The optional $opts should be a
reference to a hash, as described in MLDBM Notes.

=item Pquota::close ()

Closes all open databases.  The database methods will open the DBMs as needed,
but you must call Pquota::close() before exiting your program in order to make
sure the DBMs are properly closed.

=back

=head2 Printer Database Methods 

=over 4

=item Pquota::printer_add ($printer, $page_cost, $user_db)

Adds a printer to the printers DBM, with the associated per-page cost and
user database.

=item Pquota::printer_rm ($printer)

Removes a printer from the printers DBM.

=item Pquota::printer_set_cost ($printer, $cost)

Sets the per-page cost for the printer.

=item Pquota::printer_get_cost ($printer)

Returns the per-page cost for the printer.

=item Pquota::printer_get_cost_list ()

Returns a reference to a hash, with printer names as keys, and their per-page
costs as the values.

=item Pquota::printer_set_user_database ($printer, $user_db)

Sets the printer's associated user database.

=item Pquota::printer_get_user_database ($printer)

Returns the name of the printer's associated user database.

=item Pquota::printer_get_user_database_list ()

Returns a reference to a hash, with printer names as keys, and their per-page
costs as the values.

=item Pquota::printer_set_field ($printer, $key, $value)

Sets an arbitrary field in the printer's record.  This is in case you want
to store more information about your printers than Pquota supports natively.

=item Pquota::printer_get_field ($printer, $key);

Returns the value store in an arbitrary field in the printer's record.

=back

=head2 User Database Methods

=over 4

=item Pquota::user_add ($user, $user_db, $periodic_quota)

Adds an entry to a user database, with the indicated periodic quouta.

=item Pquota::user_rm ($user, $user_db)

Removes a user from the specified user database.

=item Pquota::user_print_pages ($user, $printer, $num_pages)

Modifies the user database to reflect the fact that the user has printed
the indicated number of pages on the specified printer.

=item Pquota::user_add_to_current ($user, $user_db, $amount)

Adds the specified amount to the user's current remaining quota.

=item Pquota::user_set_current ($user, $user_db. $amount)

Sets the user's current remaining quota.

=item Pquota::user_get_current_by_dbm ($user, $user_db)

Returns the user's current remaining quota.

=item Pquota::user_get_current_by_printer ($user, $printer)

Returns the user's current remaining quota in the user database associated
with that printer.

=item Pquota::user_reset_current ($user, $user_db)

Resets the user's current remaining quota to his periodic quota value.

=item Pquota::user_add_to_periodic ($user, $user_db, $amount)

Adds the specified amount to the user's periodic quota allotment.

=item Pquota::user_set_periodic ($user, $user_db, $amount)

Sets the user's periodic quota allotment.

=item Pquota::user_get_periodic ($user, $user_db)

Returns the user's periodic quota allotment.

=item Pquota::user_reset_total

Sets the user's total quota used to 0.

=item Pquota::user_set_field ($user, $user_db, $key, $value)

Sets an arbitrary field in the user's record.

=item Pquota::user_get_field ($user, $user_db, $key)

Returns the value stored in an arbitrary field in the user's record.

=back

=head1 TO DO

=over 4


=item *

Come up with more functionality.  Pquota currently does everything we
need, but we're sure there must be features it lacks.

=back

=head1 BUGS

None that we know of.  Please feel free to mail us with any bugs, patches,
suggestions, comments, flames, death threats, etc.

=head1 AUTHORS

David Bonner <F<dbonner@cs.bu.edu>> and Scott Savarese <F<savarese@cs.bu.edu>>

=head1 VERSION

Version 1.00  April 30, 1999

=head1 COPYRIGHT

Copyright (c) 1998, 1999 by David Bonner and Scott Savarese.  All rights
reserved. This program is free software; you can redistribute and/or modify
it under the same terms as Perl itself.

=cut

