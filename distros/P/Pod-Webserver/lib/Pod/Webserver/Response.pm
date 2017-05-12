package Pod::Webserver::Response;

use strict;
use warnings;

our $VERSION = '3.11';

# ------------------------------------------------
# The real methods are setter/getters. We only need the setters.

sub AUTOLOAD {
  my ($attrib) = $Pod::Webserver::Response::AUTOLOAD =~ /([^:]+)$/;
  $_[0]->{$attrib} = $_[1];

} # End of AUTOLOAD.

# ------------------------------------------------
# The real method is a setter/getter. We only need the getter.

sub content_ref {
  my $self = shift;
  return \$self->{content};

} # End of content_ref.

# ------------------------------------------------

sub DESTROY {};

# ------------------------------------------------

sub header {
  my $self = shift;
  push @{$self->{header}}, @_;

} # End of header.

# ------------------------------------------------

sub new {
  my ($class, $status_code) = @_;

  return bless {code=>$status_code}, $class;

} # End of new.

# ------------------------------------------------

1;
