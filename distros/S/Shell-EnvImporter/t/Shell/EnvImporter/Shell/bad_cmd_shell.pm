package Shell::EnvImporter::Shell::bad_cmd_shell;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw( Shell::EnvImporter::Shell::sh );

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
  ];

##########
sub init {
##########
  my $self  = shift;
  my %args = @_;

  $self->SUPER::init(
    name  => 'NO_SUCH_SHELL_COMMAND',
    %args,
  );

}

1;
