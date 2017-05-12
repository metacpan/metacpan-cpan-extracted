package RWDE::Web::SCGIadapter;

use strict;
use warnings;

use CGI;
use SCGI::Request;

use Error qw(:try);
use RWDE::Exceptions;

use base qw(RWDE::Web::CGIadapter);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 566 $ =~ /(\d+)/;

# set up the SCGI interaction and return the new object.  called from
# superclass new() method.
sub initialize {
  my $self = shift;
  my $params = shift;

  my $sock = $$params{sock};
  my $req = SCGI::Request->_new($sock,1); # blocking socket mode

  $req->read_env;
  %ENV = %{$req->env};

  my $cgi;

  if ($req->env->{REQUEST_METHOD} eq 'POST') {
    # read $req->connection, my $body, $req->env->{CONTENT_LENGTH};
    local *STDIN = $req->connection;
    $cgi = CGI->new();
  } else {
    $cgi = CGI->new();
  }

  CGI->_reset_globals;

  $self->{req} = $cgi;

  return;
}

sub run_command {
	my ($self, $params) = @_;

  try{
    RWDE::Web::CommandProxy->execute({ req => $self });
  }

  catch Error with{
    my $ex = shift;

	 $self->syslog_msg('info', "dispatch caught: $ex");
	 $self->syslog_msg('info', "This is beyond unusual, exceptions are caught here to avoid server going down");
  };

 	return();
}


1;
