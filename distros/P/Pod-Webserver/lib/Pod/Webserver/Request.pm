package Pod::Webserver::Request;

use strict;
use warnings;

our $VERSION = '3.11';

# ------------------------------------------------

sub method {
  return $_[0]->{method};

} # End of method.

# ------------------------------------------------

sub new {
  my $class = shift;

  return bless {@_}, $class

} # End of new.

# ------------------------------------------------

sub url {
  return $_[0]->{url};

} # End of url.

# ------------------------------------------------

1;
