package Stencil::Task::Edit;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Proc::InvokeEditor;

with 'Stencil::Executable';

our $VERSION = '0.01'; # VERSION

# METHODS

method process() {
  my $editor;

  my $file = "@{[$self->spec->file]}";

  $self->stencil->seed unless -f $file;

  $self->log->info(spec => $file);

  $editor = Proc::InvokeEditor->new(keep_file => 1);

  $editor->{filename} = $file;

  $editor->edit($self->spec->file->slurp);

  return $self;
}

1;
