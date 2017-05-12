package Shell::EnvImporter::Shell::tcsh;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Shell::EnvImporter::Shell::csh);

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
  ];

##########
sub init {
##########
  my $self = shift;
  my %args = @_;

  $self->SUPER::init(
    name      => 'tcsh',
    %args,
  );

  $self->ignore_push(qw(GROUP HOST HOSTTYPE MACHTYPE OSTYPE VENDOR));

}
1;
