package Stencil::Source;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Data;
use Data::Object::Space;

use Stencil::Error;
use Stencil::Repo;

use Template;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'data' => (
  is => 'ro',
  isa => 'Object',
  hnd => [qw(content)],
  new => 1,
);

fun new_data($self) {
  Data::Object::Data->new(from => ref $self);
}

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_repo($self) {
  Stencil::Repo->new;
}

# METHODS

method make($data, $vars) {
  my $from = $data->{from};
  my $make = $data->{make};

  return $self->process($self->template($from), $vars || {}, $make);
}

method process($text, $data, $file) {
  $file = $self->repo->store($file);

  $file->parent->mkpath;
  $file->spew($self->render($text, $data));

  return $file;
}

method render($text, $data) {
  my $output = '';

  my $template = Template->new || Template->error;

  $template->process(\$text, { self => $self, data => $data }, \$output)
    || die $template->error;

  return $output;
}

method template($name) {
  my $content;

  # find-section
  unless ($content = $self->content($name)) {
    my $space = Data::Object::Space->new(ref $self);

    die Stencil::Error->on_source_section($self, $space, $name);
  }

  $content = join("\n", @{$content || []});

  $content =~ s/^\+\=/=/gm;

  return $content;
}

1;
