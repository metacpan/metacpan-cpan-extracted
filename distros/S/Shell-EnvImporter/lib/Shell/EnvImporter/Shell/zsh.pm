package Shell::EnvImporter::Shell::zsh;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Shell::EnvImporter::Shell::sh);

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
  ];

##########
sub init {
##########
  my $self  = shift;
  my %args = @_;

  $self->SUPER::init(
    name    => 'zsh',
    %args,
  );

  $self->ignore_push(qw(OLDPWD OSTYPE USERNAME VENDOR));

}

1;
