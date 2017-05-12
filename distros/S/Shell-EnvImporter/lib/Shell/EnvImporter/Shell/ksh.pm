package Shell::EnvImporter::Shell::ksh;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw( Shell::EnvImporter::Shell::sh);

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
  ];

##########
sub init {
##########
  my $self  = shift;
  my %args = @_;

  $self->SUPER::init(
    name  => 'ksh',
    %args,
  );

}

1;
