# -*- mode: Perl; -*-
package NewsClipper::Server::CGI;

# This package implements the slower CGI-based interface to the handler
# server.

use strict;
use Carp;
use LWP::UserAgent;

use vars qw( $VERSION @ISA );
@ISA = qw( NewsClipper::Server );

$VERSION = 0.10;

use NewsClipper::Globals;

# Cache used to avoid unnecessary processing of handlers
my %downloadedCode;
my %handler_type;

# Avoid multiple warnings about the server being down
my $already_warned_server_down = 0;

# The user agent
my $userAgent;

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

  my $url = "http://" . $self->{handler_server} .
    "/cgi-bin/getinfo?field=Name&string=$handler_name&" .
    "print=Type&ncversion=$ncversion";

  my $data = _Download_URL($url);

  return (0,undef) unless defined $data;

  if ($$data =~ /Type +: (.*)/)
  {
    $handler_type{$handler_name} = $1;
    return (1,$handler_type{$handler_name});
  }
  else
  {
    lprint reformat dequote <<"    EOF";
ERROR: Couldn't parse handler type information fetched from server. Please
send email to bugreport\@newsclipper.com describing this message. Fetched
content was:
$$data
    EOF
    return (0,undef);
  }
}

# ------------------------------------------------------------------------------

# This function downloads a new handler from the handler database.  The first
# argument is the name of the handler. The second argument is the version
# number of the current handler. You should call Get_New_Handler_Version before
# calling this function.

# This function returns two values:
# - an error code: (okay, not found, failed: error message)
# - the handler (if the error code is okay)

sub Get_Handler($$)
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

  my $url;

  $url = "http://" . $self->{handler_server} .
         "/cgi-bin/gethandler?tag=$handler_name&" .
         "ncversion=$ncversion&version=$version";

  my $data = _Download_URL($url);

  # If either the download failed, or the thing we got back doesn't look like
  # a handler...
  if ((!defined $data) || ($$data !~ /package NewsClipper/))
  {
    my $error_message = reformat dequote <<"    EOF";
      failed: Couldn't download handler $handler_name. Maybe the server is
      down. Try again in a while, and send email to bugreport\@newsclipper.com
      if the problem persists.
    EOF

    $error_message .= " Message from server is: $$data\n" if defined $data;

    return ($error_message,undef);
  }

  return ('not found',undef) if $$data =~ /^Handler not found/;

  $downloadedCode{$handler_name} = $$data;
  return ('okay',$$data);
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

  my $url = "http://" . $self->{handler_server} .
    "/cgi-bin/checkversion?tag=$handler_name&ncversion=$ncversion" .
    "&debug=0";

  my $data = _Download_URL($url);

  return ('failed',undef) unless defined $data;
  return ('not found',undef) if $$data =~ /^Handler not found/;

  if ($$data =~ /(\S+)/)
  {
    my $newVersion = $1;
    return ('okay',$newVersion);
  }
  else
  {
    lprint reformat dequote <<"    EOF";
ERROR: Couldn't parse handler version information fetched from server. Please
send email to bugreport\@newsclipper.com describing this message. Fetched
content was:
$$data
    EOF
    return ('failed',undef);
  }
}

# ------------------------------------------------------------------------------

# Computes the most recent guaranteed-compatible version number for a working
# handler. Returns a status value and the version. The status can be one of
# 'okay', 'no update', 'failed', or 'not found'. The parameter $version
# should be defined.

sub _Get_Compatible_Working_Handler_Version
{
  my $self = shift;
  my $handler_name = shift;
  my $ncversion = shift;
  my $version = shift;

  my $url = "http://" . $self->{handler_server} .
    "/cgi-bin/checkversion?tag=$handler_name&ncversion=$ncversion" .
    "&version=$version&debug=1";

  my $data = _Download_URL($url);

  return ('failed',undef) unless defined $data;
  return ('not found',undef) if $$data =~ /^Handler not found/;

  return ('no update',undef) if $$data =~ /^No new version available/;

  if ($$data =~ /(\S+)/)
  {
    my $newVersion = $1;
    return ('okay',$newVersion);
  }
  else
  {
    lprint reformat dequote <<"    EOF";
ERROR: Couldn't parse handler version information fetched from server. Please
send email to bugreport\@newsclipper.com describing this message. Fetched
content was:
$$data
    EOF
    return ('failed',undef);
  }
}

# ------------------------------------------------------------------------------

# Gets the entire content from a URL. file:// supported

sub _Download_URL($)
{
  my $url = shift;

  # Create the user agent if we haven't already. (We create it on demand.)
  if (!defined $userAgent)
  {
    $userAgent = new LWP::UserAgent;
  }

  dprint "Downloading URL:";
  dprint "  $url";

  $userAgent->timeout($config{socket_timeout});
  $userAgent->proxy(['http', 'ftp'], $config{proxy})
    if $config{proxy} ne '';
  my $request = new HTTP::Request GET => "$url";
  if ($config{proxy_username} ne '')
  {
    $request->proxy_authorization_basic($config{proxy_username},
                     $config{proxy_password});
  }

  my $result;
  my $numTriesLeft = $config{socket_tries};

  do
  {
    $result = $userAgent->request($request);
    $numTriesLeft--;
  } until ($numTriesLeft == 0 || $result->is_success);

  return undef unless $result->is_success;

  my $content = $result->content;

  # Strip linefeeds off the lines
  $content =~ s/\r//gs;

  return \$content;
}

# ------------------------------------------------------------------------------

1;
