## no critic(Modules::RequireFilenameMatchesPackage)
package Coding::Error::Pathological;

use strict;
use warnings;
use Applify;

app {
  my $self = shift;
  warn "[Coding::Error::Pathological] ", $self->some_method, "\n";
  return 1;
};

sub some_method {
  return 'something';
}
