package Shell::EnvImporter::Shell::csh;

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
    name      => 'csh',
    flags     => [qw(-f -c)],
    sourcecmd => 'source',
    statusvar => '$status',
    %args,
  );

  $self->ignore_push(qw(GROUP HOST HOSTTYPE MACHTYPE OSTYPE VENDOR));


}


################
sub env_export {
################
  my $self   = shift;
  my %values = (@_ == 1 ? %{$_[0]} : @_);

  my @sets;
  foreach my $var (sort keys %values) {
    if (defined($values{$var})) {
      push(@sets, "setenv $var $values{$var}");
    } else {
      push(@sets, "unsetenv $var");
    }
  }

  return join($self->cmdsep, @sets);

}

1;
