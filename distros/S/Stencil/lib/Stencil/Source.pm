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

our $VERSION = '0.03'; # VERSION

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

=encoding utf8

=head1 NAME

Stencil::Source

=cut

=head1 ABSTRACT

Source generator base class

=cut

=head1 SYNOPSIS

  use Stencil::Repo;
  use Stencil::Source::Test;

  my $repo = Stencil::Repo->new;

  $repo->store->mkpath;

  my $source = Stencil::Source::Test->new;

  # $source->make($oper, $data);

=cut

=head1 DESCRIPTION

This package provides a source generator base class and is meant to be
extended.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 data

  data(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 repo

  repo(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 make

  make(HashRef $oper, HashRef $vars) : InstanceOf["Path::Tiny"]

The make method executes the instructions, then returns the file.

=over 4

=item make example #1

  # given: synopsis

  $source->make({ from => 'class', make => 'MyApp.pm' }, { name => 'MyApp' });

=back

=cut

=head2 process

  process(Str $text, HashRef $vars, Str $file) : InstanceOf["Path::Tiny"]

The process method renders the template, then creates and returns the file.

=over 4

=item process example #1

  # given: synopsis

  $source->process('use [% data.name %]', { name => 'MyApp' }, 'example.pl');

=back

=cut

=head2 render

  render(Str $text, HashRef $vars) : Str

The render method processes the template and returns the content.

=over 4

=item render example #1

  # given: synopsis

  $source->render('use [% data.name %]', { name => 'MyApp' });

=back

=cut

=head2 template

  template(Str $name) : Str

The template method returns the named content declared in the C<__DATA__>
section of the generator.

=over 4

=item template example #1

  # given: synopsis

  $source->template('class');

=back

=over 4

=item template example #2

  # given: synopsis

  $source->template('class-test');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/stencil/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/stencil/wiki>

L<Project|https://github.com/iamalnewkirk/stencil>

L<Initiatives|https://github.com/iamalnewkirk/stencil/projects>

L<Milestones|https://github.com/iamalnewkirk/stencil/milestones>

L<Contributing|https://github.com/iamalnewkirk/stencil/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/stencil/issues>

=cut
