package Tak::MyScript;

use Moo;

extends 'Tak::Script';

sub _my_script_package { 'Tak::MyScript' }

sub BUILD {
  my ($self) = @_;
  $self->_load_file('Takfile') if -e 'Takfile';
}

sub _load_file_in_my_script {
  require $_[1];
}

1;
