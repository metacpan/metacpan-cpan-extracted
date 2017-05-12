package RWDE::DB::Immutable;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

sub update_record {
  my ($self, $params) = @_;

  return throw RWDE::DevelException({ info => 'You may not modify or update immutable records through the API' . $self  });
}

sub create_record {
  my ($self, $params) = @_;

  return throw RWDE::DevelException({ info => 'You may not modify or update immutable records through the API' . $self });
}

1;
