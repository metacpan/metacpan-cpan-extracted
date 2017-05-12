package Shell::EnvImporter::Shell::sh;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Shell::EnvImporter::Shell);

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
  ];

##########
sub init {
##########
  my $self = shift;
  my %args = @_;

  $self->SUPER::init(
    %args,
  );

}

1;
