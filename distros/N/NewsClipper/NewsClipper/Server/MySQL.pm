# -*- mode: Perl; -*-
package NewsClipper::Server::MySQL;

# This package implements the fast MySQL-based interface to the handler
# server.

use strict;
use Carp;
use DBI;
use DBD::mysql;

use vars qw( $VERSION @ISA );
@ISA = qw( NewsClipper::Server );

$VERSION = 0.10;

use NewsClipper::Globals;

# Caches used to avoid unnecessary processing of handlers
my %downloadedCode;
my %handler_type;

# Avoid multiple warnings about the server being down
my $already_warned_server_down = 0;

# The database handle;
my $dbh = undef;

# ------------------------------------------------------------------------------

sub new
{
  my $proto = shift;

  # We take the ref if "new" was called on an object, and the class ref
  # otherwise.
  my $class = ref($proto) || $proto;

  # Create an "object"
  my $self = {};

  # Make the object a member of the class
  bless ($self, $class);

  return $self;
}

# ------------------------------------------------------------------------------

# Connect to the database, storing the DB connection in $dbh for the
# duration of the run. Returns 1 if successful, 0 if not.

sub _Connect_To_DB
{
  my $self = shift;

  return $dbh if defined $dbh;

  dprint "Attempting to connect to handler database.";

  my $code =<<"  EOF";
    return
      DBI->connect('DBI:mysql:handlers:$self->{handler_server}','webuser');
  EOF

  $dbh = $self->_Talk_To_Server($code);

  if (defined $dbh)
  {
    dprint "Database connect succeeded.";
    return(1);
  }
  else
  {
    dprint "Database connect failed.";
    return(0);
  }
}

# ------------------------------------------------------------------------------

# Disconnect from the database.

sub _Disconnect_From_DB
{
  if (defined $dbh)
  {
    $dbh->disconnect();
    dprint "Disconnected from database";
  }
}

# ------------------------------------------------------------------------------

# Evals code that talks to the server, taking the socket timeout and socket
# retries into account. The code should result in a nonzero, defined value if
# successful. Returns 2 values. The first value is 1 or 0 depending on whether
# the connect succeeded, and the second value is the result of eval'ing the
# code.

sub _Talk_To_Server
{
  my $self = shift;
  my $code = shift;

  # Connect to the database if we haven't already. (We connect on demand.)
  # Also avoid recursion when _Connect_To_DB calls this function.
  {
    my $calling_function = @{[caller(1)]}[3];

    if (!defined $dbh &&
      $calling_function ne 'NewsClipper::Server::MySQL::_Connect_To_DB')
    {
      unless ($self->_Connect_To_DB())
      {
        return (0,undef);
      }
    }
  }

  local $SIG{ALRM} = sub { die "database timeout" };

  my $numTriesLeft = $config{socket_tries};
  my $errors = '';
  my $completed_successfully = 0;
  my $return_value;

  do
  {
    local $SIG{__WARN__} = sub { $errors .= $_[0] unless $errors eq $_[0] };

    # Wrap in an eval to trap die's in the DBI code
    alarm($config{socket_timeout});
    $return_value = eval $code;
    alarm(0);

    $completed_successfully = 1 if $@ eq '' && $errors eq '';

    $numTriesLeft--;
  } until ($numTriesLeft == 0 || $completed_successfully);

  if ($completed_successfully)
  {
    return(1,$return_value);
  }
  else
  {
    if ($@ =~ /database timeout/)
    {
      dprint "Could not access database: Connection timed out";
      lprint "Could not access database: Connection timed out";
    }
    elsif ($errors ne '')
    {
      dprint "Could not access database: $errors";
      lprint "Could not access database: $errors";
    }
    elsif (defined $dbh)
    {
      dprint "Could not access database: $DBI::errstr";
      lprint "Could not access database: $DBI::errstr";
    }
    else
    {
      dprint "Could not access database. An unknown error occurred";
      lprint "Could not access database. An unknown error occurred";
    }

    return(0,undef);
  }
}

# ------------------------------------------------------------------------------

# Download the handler type from the remote server, caching it locally in
# %handler_type. The first return value is the status of the request, and the
# second is the handler type. The status is 0 if the server can't be
# contacted, or the returned data can't be parsed.

sub Get_Handler_Type
{
  my $self = shift;
  my $handler_name = shift;
  my $ncversion = shift;

  dprint "Downloading handler type information.\n";

  if (exists $handler_type{$handler_name})
  {
    dprint "Reusing cached handler type information " .
      "($handler_name is $handler_type{$handler_name})";
    return (1,$handler_type{$handler_name});
  }

  my $table = _Get_Table($ncversion);

  my $query = qq{ SELECT Type FROM $table WHERE Name like '$handler_name'
    and Status like 'Working'
    ORDER BY Version DESC };

  my $talk_code =<<"  EOF";
     return scalar \$dbh->selectrow_array(q{$query});
  EOF

  my ($succeeded,$type) = $self->_Talk_To_Server($talk_code);

  return (0,undef) unless $succeeded;

  $handler_type{$handler_name} = $type;
  return (1,$type);
}

# ------------------------------------------------------------------------------

# This function downloads a new handler from the handler database.  The first
# argument is the name of the handler. The second argument is the version
# number of the current handler. You should call Get_New_Handler_Version before
# calling this function.

# This function returns two values:
# - an error code: (okay, not found, failed: error message)
# - the handler (if the error code is okay)

sub Get_Handler
{
  my $self = shift;
  my $handler_name = shift;
  my $version = shift;
  my $ncversion = shift;

  dprint "Downloading code for handler \"$handler_name\"";

  if (defined $downloadedCode{$handler_name})
  {
    dprint "Reusing already downloaded code.";
    return ('okay',$downloadedCode{$handler_name});
  }

  my $table = _Get_Table($ncversion);

  my $query = qq{ SELECT Code FROM $table WHERE Name like '$handler_name'
    and Status like 'Working'
    ORDER BY Version DESC };

  my $talk_code =<<"  EOF";
     return scalar \$dbh->selectrow_array(q{$query});
  EOF

  my ($succeeded,$code) = $self->_Talk_To_Server($talk_code);

  # If either the download failed, or the thing we got back doesn't look like
  # a handler...
  unless ($succeeded)
  {
    my $error_message = reformat dequote <<"    EOF";
      failed: Couldn't download handler $handler_name. Maybe the server is
      down. Try again in a while, and send email to bugreport\@newsclipper.com
      if the problem persists. Check the run log for additional information.
    EOF

    return ($error_message,undef);
  }

  return ('not found',undef) if $succeeded && !defined $code;

  $downloadedCode{$handler_name} = $code;
  return ('okay',$code);
}

# ------------------------------------------------------------------------------

# Computes the most recent version number for a working handler.
# Returns a status value and the version. The status can be one of 'okay',
# 'failed', or 'not found'.

sub _Get_Latest_Working_Handler_Version
{
  my $self = shift;
  my $handler_name = shift;
  my $ncversion = shift;

  my $table = _Get_Table($ncversion);

  my $query = qq{ SELECT Version FROM $table WHERE Name like '$handler_name'
    and Status like 'Working' ORDER BY Version DESC };

  my $talk_code =<<"  EOF";
     return scalar \$dbh->selectrow_array(q{$query});
  EOF

  my ($succeeded,$version) = $self->_Talk_To_Server($talk_code);

  if ($succeeded)
  {
    if (defined $version)
    {
      return ('okay',$version);
    }
    else
    {
      return ('not found',undef);
    }
  }
  else
  {
    lprint reformat dequote <<"    EOF";
ERROR: Couldn't get handler version information from server. Please
send email to bugreport\@newsclipper.com describing this message.
    EOF

    return ('failed',undef);
  }
}

# ------------------------------------------------------------------------------

sub _Get_Table
{
  my $version = shift;

  my $table = $version;
  $table =~ s/\./_/g;

  return $table;
}

# ------------------------------------------------------------------------------

# Computes the most recent guaranteed-compatible version number for a working
# handler.  Returns a status value and the version. The status can be one of
# 'okay', 'no update', 'failed', or 'not found'. The parameter $version
# should be defined.

sub _Get_Compatible_Working_Handler_Version
{
  my $self = shift;
  my $handler_name = shift;
  my $ncversion = shift;
  my $version = shift;

  my $table = _Get_Table($ncversion);

  # Truncate to two decimal places, and increment the hundredths place so we
  # can query for < $version
  my $lower_version = sprintf("%0.2f",int($version * 100)/100);
  my $upper_version = sprintf("%0.2f",int($version * 100)/100 + .01);

  my $query = qq{ SELECT Version FROM $table WHERE Name like '$handler_name'
    and Status like 'Working'
    and Version < $upper_version and Version >= $lower_version
    ORDER BY Version DESC };

  my $talk_code =<<"  EOF";
     return scalar \$dbh->selectrow_array(q{$query});
  EOF

  my ($succeeded,$new_version) = $self->_Talk_To_Server($talk_code);

  if ($succeeded)
  {
    if (defined $new_version)
    {
      return ('okay',$new_version);
    }
    # We have to differentiate between 'not found' and 'no update'
    else
    {
      my $query = qq{ SELECT Name FROM $table WHERE Name like '$handler_name' };

      my $talk_code =<<"      EOF";
         return scalar \$dbh->selectrow_array(q{$query});
      EOF

      my ($succeeded2,$name) = $self->_Talk_To_Server($talk_code);

      if (defined $name)
      {
        return ('no update',undef);
      }
      else
      {
        return ('not found',undef);
      }
    }
  }
  else
  {
    return ('failed',undef);
  }
}

# ------------------------------------------------------------------------------

END
{
  _Disconnect_From_DB();
}

1;
