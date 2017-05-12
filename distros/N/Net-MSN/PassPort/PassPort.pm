# Net::MSN::PassPort - PassPort class used by Net::MSN and Net::MSN::SB.
# Originally written by: 
#  Adam Swann - http://www.adamswann.com/library/2002/msn-perl/
# Modified by:
#  David Radunz - http://www.boxen.net/
#
# $Id: PassPort.pm,v 1.1 2003/10/18 03:10:49 david Exp $ 

package Net::MSN::PassPort;

use strict;
use warnings;

BEGIN {
  # Modules
  # CPAN
  use LWP::UserAgent;

  # Package specific
  use Net::MSN::Debug;

  use vars qw($VERSION);

  $VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 
}

sub new {
  my ($class, %args) = @_;

  my $self = bless({
    'Version'           =>      $VERSION,
    'Debug'             =>      0,
    'Debug_Lvl'         =>      0,
    'Debug_Log'         =>      '',
    'Debug_STDERR'      =>      1,
    'Debug_STDOUT'	=>	0,
    'Debug_LogCaller'   =>      1,
    'Debug_LogTime'     =>      1,
    'Debug_LogLvl'      =>      1,
    '_L'                =>      '',
    '_Log'		=>	''
  }, ref($class) || $class);

  $self->set_options(\%args);
  $self->_new_Log_obj();

  return $self;
}

sub set_options {
  my ($self, $opts) = @_;

  my %opts = %$opts;
  foreach my $key (keys %opts) {
    if (ref $opts{$key} eq 'HASH') {
      $self->{$key} =
        \%{ merge($opts{$key}, $self->{$key}) };
    } else {
      $self->{$key} = $opts{$key};
    }
  }
}

sub _new_Log_obj {
  my ($self) = @_;

  return if ((defined $self->{_L} && $self->{_L}) ||
    (defined $self->{_Log} && $self->{_Log}));

  # Create a new Net::MSN::Debug object for debug
  $self->{_L} = new Net::MSN::Debug(
    'Debug'     =>  $self->{Debug},
    'Level'     =>  $self->{Debug_Lvl},
    'LogFile'   =>  $self->{Debug_Log},
    'STDERR'    =>  $self->{Debug_STDERR},
    'STDOUT'    =>  $self->{Debug_STDOUT},
    'LogCaller' =>  $self->{Debug_LogCaller},
    'LogTime'   =>  $self->{Debug_LogTime},
    'LogLevel'  =>  $self->{Debug_LogLvl}
  );

  die "Unable to create L obj!\n"
    unless (defined $self->{_L} && $self->{_L});

  $self->{_Log} = $self->{_L}->get_log_obj();

  die "Unable to create Log obj!\n"
    unless (defined ($self->{_Log} && $self->{_Log}));
}

sub login {
  my ($self, $handle, $password, $auth_key) = @_;

  my $passport_url = 'https://login.passport.com/login2.srf';

  my %headers = (
    'Authorization' => 'Passport1.4 '.
      'OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,'.
      'sign-in='. $handle.
      ',pwd='. $password. ','. $auth_key,
    'Connection'    => 'Keep-Alive',
    'Cache-Control' => 'no-cache'
  );

  my $ua = new LWP::UserAgent;
  $ua->agent('MSMSGS');
  my $res = $ua->get($passport_url, %headers);

  $self->{_Log}("Logging into PassPort on: ". $passport_url. " as: ".
    $handle, 3); 

  if ($res->is_success) {
    $self->{_Log}("Authentication Successful", 3);
    my $auth_info = $res->header('Authentication-Info');
    unless (defined $auth_info) {
      $self->{_Log}("No Authentication-Info Header Sent", 1);
      return;
    }
    if ($auth_info =~ /from-PP\=\'(.+?)\'\,/) {
      return $1;
    } else {
      $self->{_Log}("Unable to parse Authentication-Info for Session Key", 1);
    }
  } else {
    if ($res->status_line =~ /401/) {
      $self->{_Log}("Authentication Failed");
    } else {
      die "Error while getting ", $res->request->uri,
	" -- ", $res->status_line, "\nAborting";
    }
  }
}

return 1;
