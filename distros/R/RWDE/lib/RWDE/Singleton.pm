# Singleton variables and functions
package RWDE::Singleton;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

sub new {
  my ($class, $params) = @_;

  if (caller() ne $class) {
    my ($package, $filename, $line) = caller();
    throw RWDE::DevelException({ info => " ($package) from $filename Line: $line is trying to access the constructor directly. Use get_instance instead." });
  }

  my $self = { _data => 'something' };

  bless($self, $class);

  $self->initialize($params);

  return $self;
}

sub initialize {
  my ($self, $params) = @_;

  return ();
}

# do nothing.  here just to shut up TT when AUTOLOAD is present
sub DESTROY {

}

1;
