package Shell::EnvImporter::Shell::perl;

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
    name      => 'perl',
    flags     => [qw(-e)],

    sourcecmd => 'do',
    envcmd    => 'while (($k,$v) = each(%ENV)) { print "$k=$v\n"}',

    statusvar => '@{[$!+0]}',

    %args,
  );

}


##################
sub echo_command {
##################
  my $self = shift;
  my $str  = $self->dquote("@_\\n");

  return "print $str";

}


1;
