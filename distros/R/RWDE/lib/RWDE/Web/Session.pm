## @file
# (Enter your file info here)
#
# @copy 2007 MailerMailer LLC
# $Id: Session.pm 465 2008-05-10 01:54:58Z damjan $

## @class RWDE::Web::Session
# (Enter RWDE::Web::Session info here)
package RWDE::Web::Session;

use strict;
use warnings;

use Apache::Session::Postgres;
use Error qw(:try);

use RWDE::Exceptions;

use base qw(RWDE::DB::DefaultDB);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 572 $ =~ /(\d+)/;

# Session values are retrieved and set using the session hash key names,
# just as if you were accessing the hash directly.
#
#  <% USE s = session %>
#  <% GET s.something %>
#  <% SET s.whatever = 234 %>
# @return Session
## @cmethod object new()
# Returns a container for the session hash from the request object
# pnotes section.
# @return
sub new {
  my ($class, $session_id) = @_;

  my $self = { verbose => 0 };

  bless $self, $class;

  my %session;
  my $dbh = $self->get_dbh();

  # Check if the key is in database; raises an exception if unable to create
  # if no session_id supplied, creates a new entry
  tie %session, 'Apache::Session::Postgres', $session_id,
    {
    Handle => $dbh,
    Commit => 0,
    };

  $self->{_session} = \%session
    or throw RWDE::Web::SessionMissingException({ info => 'No session found.' });

  return $self;
}

sub get_ccrcontext {
	my ($self, $params) = @_;
	
	return 7;
}
## @method void remove()
# (Enter remove info here)
sub remove {
  my ($self, $params) = @_;

  my %session = %{ $self->{_session} }
    or throw RWDE::Web::SessionMissingException({ info => 'No session found.' });

  tied(%{ $self->{_session} })->delete();    # session failure ignored here.

  return;
}

sub set_limited {
	my ($self, $params) = @_;
	
	$self->{_limited} = 1;
	
	return;
}

sub set_not_limited {
	my ($self, $params) = @_;
	
	$self->{_limited} = undef;	
	
	return;
}

## @method void verbose()
# Turn on/off debugging to the error_log/STDERR.  Sets verbosity to
# $level.  Currently only boolean.
sub verbose {
  my ($self, $v) = @_;

  $self->{verbose} = $v || 0;
  warn "session $self verbose => $v\n";

  return;
}

## @method object keys()
# Returns the keys of the session hash.
# @return
sub keys {
  my $self = shift;

  #if we are in a limitted mode
  if (defined $self->{_limited}){
    return CORE::keys %{ $self->{_session}->{limited_storage} };
  }
  else{
    return CORE::keys %{ $self->{_session} };
  }
}

## @method object retrieve($session_id)
# (Enter retrieve info here)
# @param session_id  (Enter explanation for param here)
# @return (Enter explanation for return value--Session--here)
sub retrieve {
  my ($self, $params) = @_;

  my $session;

  try {
    my $session_id = $$params{session_id}
      or throw RWDE::DataNotFoundException({ info => 'No session_id specified' });

    #Retrive the session
    $session = $self->new($session_id);
  }

  catch Error with {
    my $ex = shift;

    throw RWDE::DataNotFoundException({ info => 'Could not retrieve the session: ' . $ex });
  };

  return $session;
}

## @method void dump()
# (Enter dump info here)
sub dump {
  my $self = shift;

  require Data::Dumper;    # pull in only if we're in verbose mode.
  $Data::Dumper::Terse = 1;
  foreach my $k (CORE::keys %{ $self->{_session} }) {
    if (ref $self->{_session}->{$k}) {
      warn "session $self var $k => " . Data::Dumper::Dumper($self->{_session}->{$k}) . "\n";
    }
    else {
      warn "session $self var $k => $self->{_session}->{$k}\n";
    }
  }

  return;
}

# use autoload to set and get the fields of the session.  setting a field
# automatically updates the "timestamp" field to force updating the backing
# store by Apache::Session::Postgres;

use vars qw($AUTOLOAD);

## @cmethod object AUTOLOAD()
# (Enter AUTOLOAD info here)
# @return
sub AUTOLOAD {
  my $self = shift;

	if (not defined $self->{_session}){
		throw RWDE::DevelException({ info => 'No session found. '})
	}

  my $name = $AUTOLOAD;
  $name =~ s/.*://;    # strip fully-qualified portion

	#if we are in a limitted mode
	if (defined $self->{_limited}){

	  if (@_) {            # given value, so set it.
	    $self->{_session}->{limited_storage}->{$name} = $_[0];	
	    $self->{_session}->{timestamp} = time;
	    warn "session $self->{_session}->{_session_id} set $name => $_[0]\n"
	      if $self->{verbose};
	  }
	  return $self->{_session}->{limited_storage}->{$name};	
	}	
	
	else{
	  if (@_) {            # given value, so set it.

	    $self->{_session}->{$name} = $_[0];
	    $self->{_session}->{timestamp} = time;
	    warn "session $self->{_session}->{_session_id} set $name => $_[0]\n"
	      if $self->{verbose};
	  }		
	  return $self->{_session}->{$name};		
	}
}

## @cmethod void DESTROY()
# only here for debugging when verbose set.
sub DESTROY {
  my $self = shift;

  if ($self->{verbose} and ref($self->{_session}) eq 'HASH') {
    $self->dump();
  }

  return;
}

1;
