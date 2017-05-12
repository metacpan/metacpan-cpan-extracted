package Search::InvertedIndex::DB::Mysql;
# $RCSfile: Mysql.pm,v $ $Revision: 1.2 $ $Date: 2000/11/29 18:36:03 $ $Author: snowhare $
use DBI;
use Carp;
use Class::NamedParms;
use Class::ParmList;
use vars qw (@ISA $VERSION);
use strict;

@ISA     = qw(Class::NamedParms);
$VERSION = "1.01";

# This is supposed to keep the same database table
# from being opened more than once. But I'm not sure
# if it really matters, because of how I do the
# locking.
my $open_maps = {};

=head1 NAME

Search::InvertedIndex::DB::Mysql - A MySQL database interface object for Search::InvertedIndex

=head1 SYNOPSIS

  use Search::InvertedIndex::DB::Mysql;

  my $db = Search::InvertedIndex::DB::Mysql->new({
              -db_name => 'searchdb',
             -hostname => 'db.domain.com',
             -username => 'dbuser',
             -password => 'dbuserpw',
           -table_name => 'indextablename',
            -lock_mode => 'EX' });

  my $inv_map = Search::InvertedIndex->new({ -database => $db });

  my $query = Search::InvertedIndex::Query->new(...);
  my $result = $inv_map->search({ -query => $query });

  my $update = Search::InvertedIndex::Update->new(...);
  my $result = $inv_map->update({ -update => $update });

  $inv_map->close;

=head1 DESCRIPTION

An interface allowing Search::InvertedIndex to store and retrieve
data from Mysql database tables. All of the data is stored in a
single table, which will be created automatically if it does not
exist when the new method is called.

The new method takes up to six parameters, two of which are
required.

=over 4

=item C<-db_name>

Mysql database name. Required.

=item C<-table_name>

Table within the database to use. *CAUTION* If this table exists, the
clear method will erase the contents WITHOUT verifying that the table
contains data the module understands. If you point the module to an
existing table you do so at your own risk! Required.

=item C<-hostname>

Mysql database host. Default: database server is on the local machine.

=item C<-username>

User for connecting to the Mysql server. The user must have appropriate
authority for the operations you are performing or Mysql may complain.
Default: none.

=item C<-password>

Password for the User. Default: none.

=item C<-lock_mode>

Locking status for the database table. EX, SH, or UN. EX will attempt to
obtain a WRITE lock on the table, SH a READ lock, and UN will not request
one at all. Tables may be created and modified in any mode, but EX is
obviously recommended.

=back

=head1 CHANGES

 1.00 2000.11.28 - First version.

=head1 COPYRIGHT

This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Michael Cramer <cramer@webkist.com>, based on
Search::InvertedIndex::DB::DB_File_SplitHash by Benjamin Franz.

=head1 NOTES

This module is not tested during installation due to its need for
MySQL support in Perl and associated access permissions and so on. 

You *MUST* have the DBI and DBD::mysql modules installed to be able to use this module.

Theoretically, someone could use this module as a starting point for creating
support for all kinds of DBI supported databases.

=head1 SEE ALSO

Search::InvertedIndex Search::InvertedIndex::DB::DB_File_SplitHash DBI DBD::mysql

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = Class::NamedParms->new(qw(-db_name
                                          -hostname
                                          -username
                                          -password
                                          -table_name
                                          -open_status
                                          -db_handle
                                          -put_handle
                                          -get_handle
                                          -del_handle
                                          -lock_mode
                                          -lock_status));

    bless $self,$class;

   # Read any passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift;
    } elsif ($#_ > 0) {
        %$parm_ref = @_;
    }

    # Check the passed parms and set defaults as necessary
    my $parms = Class::ParmList->new({ -parms => $parm_ref,
                                       -legal => [-db_name,
                                                  -hostname,
                                                  -username,
                                                  -password,
                                                  -table_name,
                                                  -lock_mode],
                                    -required => [-db_name, -table_name],
                                    -defaults => { -username => undef,
                                                   -password => undef,
                                                   -hostname => undef,
                                                 -put_handle => undef,
                                                 -get_handle => undef,
                                                 -del_handle => undef,
                                                  -lock_mode => 'SH' } });

    if (not defined $parms) {
           my $error_message = Class::ParmList->error;
           croak (__PACKAGE__ . "::new() - $error_message\n");
    }
    $self->SUPER::set($parms->all_parms);
    $self->SUPER::set( { -open_status => 0 } );

    $self;
}

sub open {
  my $self = shift;

  my($db_name,
     $hostname,
     $username,
     $password,
     $table,
     $lock_mode) = $self->SUPER::get(-db_name, -hostname, -username, -password, -table_name, -lock_mode);

  if ($db_name eq '') {
    croak (__PACKAGE__ . "::open() - Called without a -db_name\n");
  }
  if (defined $open_maps->{"$db_name;$table"}) {
    croak (__PACKAGE__ . "::open() - Attempted to open a database multiple times\n");
  }
  my $dbh = DBI->connect(join(":", "dbi", "mysql", $db_name, $hostname), $username, $password)
    || croak (__PACKAGE__ . "::open() - Couldn't connect to $db_name\n");

  unless ( grep m/^(`?)$table\1$/, $dbh->tables ) {
    if ($lock_mode eq "EX" or $lock_mode eq "UN") {
      my $sth = $dbh->prepare("CREATE TABLE $table (
                                 ii_key CHAR(128) not null primary key,
                                 ii_val LONGBLOB )")
        || croak (__PACKAGE__ . "::open() - Couldn't prepare CREATE of $table: $DBI::errstr\n");
      $sth->execute
        || croak (__PACKAGE__ . "::open() - Couldn't execute CREATE of $table: $DBI::errstr\n");
    } else {
      croak (__PACKAGE__ . "::open() - table $table doesn't exist in $db_name\n");
    }
  }

  $self->SUPER::set( { -open_status => 1, -db_handle => $dbh } );
  $self->SUPER::set( { -lock_status => 'UN' } );
  $open_maps->{"$db_name;$hostname;$table"} = $dbh;
  $self->lock( -lock_mode => 'UN');

}

sub close {
  my $self = shift;

  $self->lock(-lock_mode => 'UN');

  my($dbh, $table, $lock_mode, $lock_status, $db_name, $hostname)
    = $self->SUPER::get(-db_handle, -table_name, -lock_mode, -lock_status, -db_name, -hostname);
  $dbh->disconnect;

  $self->SUPER::set( { -open_status => 0 } );
  $self->SUPER::clear(qw(-db_handle));
  delete $open_maps->{"$db_name;$hostname;$table"};
}

sub lock {
  my $self = shift;

  my($parm_ref) = {};
  if ($#_ == 0) {
    $parm_ref = shift;
  } elsif ($#_ > 0) {
    %$parm_ref = @_;
  }
  my $parms = Class::ParmList->new ({-parms => $parm_ref,
                                     -legal => [],
                                  -required => [-lock_mode]});
  if (not defined $parms) {
    my $error_message = Class::ParmList->error;
    croak (__PACKAGE__ . "::lock() - $error_message\n");
  }

  my($db_name, $hostname, $dbh, $table, $old_lock_mode, $lock_status)
    = $self->SUPER::get(-db_name, -hostname, -db_handle, -table_name, -lock_mode, -lock_status);

  if (not defined $open_maps->{"$db_name;$hostname;$table"}) {
    croak (__PACKAGE__ . "::lock() - $db_name is not open. Can't lock.\n");
  }

  my($new_lock_mode) = $parms->get(-lock_mode);

  return if $new_lock_mode eq $old_lock_mode;

  my $sth = $dbh->prepare("UNLOCK TABLES")
    || croak (__PACKAGE__ . "::lock() - Couldn't prepare UNLOCK for $table\n");
  $sth->execute
    || croak (__PACKAGE__ . "::lock() - Couldn't UNLOCK $table\n");
  $self->SUPER::set( { -lock_status => 'UN' } );

  if ($new_lock_mode eq 'SH') {
    my $sth = $dbh->prepare("LOCK TABLES $table READ")
      || croak (__PACKAGE__ . "::lock() - Couldn't prepare SH lock for $table\n");
    $sth->execute
      || croak (__PACKAGE__ . "::lock() - Couldn't SH lock $table\n");
    $sth->finish;
    $self->SUPER::set( { -lock_status => 'SH' } );

  } elsif ($new_lock_mode eq 'EX') {
    my $sth = $dbh->prepare("LOCK TABLES $table WRITE")
      || croak (__PACKAGE__ . "::lock() - Couldn't prepare EX lock for $table\n");
    $sth->execute
      || croak (__PACKAGE__ . "::lock() - Couldn't EX lock $table\n");
    $sth->finish;
    $self->SUPER::set( { -lock_status => 'EX' } );

  }

}

sub status {
  my $self = shift;
  my $request = lc $_[0];

  if ($request eq '-open') { return $self->SUPER::get(-open_status); }
  if ($request eq '-lock_mode' or $request eq '-lock') { return uc($self->SUPER::get(-lock_status)); }
  croak (__PACKAGE__ . "::status() - invalid request: $request\n");
}

sub DESTROY {
  my $self = shift;
  $self->close;
}

sub put {
  my $self = shift;
  my $parm_ref = {};
  if ($#_ == 0) {
    $parm_ref = shift;
  } elsif ($#_ > 0) {
    %$parm_ref = @_;
  }

  my $parms = {};
  %$parms = map { (lc($_), $parm_ref->{$_}) } keys %$parm_ref;
  my @key_list = keys %$parms;
  if ($#key_list != 1) {
    croak (__PACKAGE__ . "::put() - incorrect number of parameters\n");
  }

  my $key = $parms->{'-key'};
  if (not defined $key) {
    croak (__PACKAGE__ . "::put() - invalid -key.\n");
  }

  my $value = $parms->{'-value'};
  if (not defined $value) {
    croak (__PACKAGE__ . "::put() - invalid -value.\n");
  }
  my($dbh, $table, $sth) = $self->SUPER::get(-db_handle, -table_name, -put_handle);

  ## For some reason, this doesn't work. MySQL (or DBD::mysql, or DBI) has
  ## a bug that doesn't like some of the values we're trying to insert
  ## via the execute method.

#   if (!$sth) {
#     $sth = $dbh->prepare("REPLACE INTO $table (ii_key, ii_val) VALUES (?, ?)");
#     return 0 unless $sth;
#     $self->SUPER::set({-put_handle => $sth});
#   }
#
#   $sth->execute($key, $value) || return 0;

  ## This DOES work, which doesn't make much sense to me. For some reason
  ## an explicit quote works, but binding the values through the
  ## execute method doesn't.

  $sth = $dbh->prepare("REPLACE INTO $table (ii_key, ii_val) VALUES (" . $dbh->quote($key) . ", " .
                                                                         $dbh->quote($value) . ")");
  $sth->execute;

  $sth->finish;
  1;
}

sub get {
  my $self = shift;
  my $parm_ref = {};
  if ($#_ == 0) {
    $parm_ref = shift;
  } elsif ($#_ > 0) {
    %$parm_ref = @_;
  }

  my $parms = {};
  %$parms = map { (lc($_), $parm_ref->{$_}) } keys %$parm_ref;
  my @key_list = keys %$parms;
  if ($#key_list != 0) {
    croak (__PACKAGE__ . "::get() - incorrect number of parameters\n");
  }

  my $key = $parms->{'-key'};
  if (not defined $key) {
    croak (__PACKAGE__ . "::get() - invalid -key.\n");
  }

  my($dbh, $table, $sth) = $self->SUPER::get(-db_handle, -table_name, -get_handle);
  if (!$sth) {
    $sth = $dbh->prepare("SELECT ii_val FROM $table WHERE ii_key = ?") || return 0;
    $self->SUPER::set({-get_handle => $sth});
  }

  $sth->execute($key);

  my($value) = $sth->fetchrow_array;
  $sth->finish;
#   $value =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
  return $value;
}

sub delete {
  my $self = shift;
  my $parm_ref = {};
  if ($#_ == 0) {
    $parm_ref = shift;
  } elsif ($#_ > 0) {
    %$parm_ref = @_;
  }

  my $parms = {};
  %$parms = map { (lc($_), $parm_ref->{$_}) } keys %$parm_ref;
  my @key_list = keys %$parms;
  if ($#key_list != 0) {
    croak (__PACKAGE__ . "::delete() - incorrect number of parameters\n");
  }

  my $key = $parms->{'-key'};
  if (not defined $key) {
    croak (__PACKAGE__ . "::get() - invalid -key.\n");
  }

  my($dbh, $table, $sth) = $self->SUPER::get(-db_handle, -table_name, -del_handle);
  if (!$sth) {
    $sth = $dbh->prepare("DELETE FROM $table WHERE ii_key = ?") || return 0;
    $self->SUPER::set({-del_handle => $sth});
  }

  $sth->execute($key) || return 0;
  $sth->finish;
  return 1;
}

sub exists {
  my $self = shift;
  return $self->get(@_) ? 1 : 0;
}

sub clear {
  my $self = shift;
  my($dbh, $table) = $self->SUPER::get(-db_handle, -table_name);
  my $sth = $dbh->prepare("DELETE FROM $table") || return 0;
  $sth->execute || return 0;
  $sth->finish;
  return 1;
}

1;
