package Stencil::Log;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use FlightRecorder;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  req => 1,
);

has 'file' => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_file($self) {
  $self->repo->store('logs', join '.', $$, time, 'log')->touch;
}

has handler => (
  is => 'ro',
  isa => 'Object',
  hnd => [qw(info debug warn fatal output)],
  new => 1
);

fun new_handler($self) {
  FlightRecorder->new( auto => $self->file->openw_utf8, format => '[{head_level}] {head_message}', level => 'info');
}

# METHODS

after info(@args) {
  $self->output(\*STDOUT);
}

after warn(@args) {
  $self->output(\*STDOUT);
}

after fatal(@args) {
  $self->output(\*STDOUT);
}

1;

=encoding utf8

=head1 NAME

Stencil::Log

=cut

=head1 ABSTRACT

Represents a Stencil log file

=cut

=head1 SYNOPSIS

  use Stencil::Log;
  use Stencil::Repo;

  my $repo = Stencil::Repo->new;

  $repo->store('logs')->mkpath;

  my $log = Stencil::Log->new(repo => $repo);

=cut

=head1 DESCRIPTION

This package provides a class which represents a Stencil log file.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 file

  file(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 handler

  handler(InstanceOf["FlightRecorder"])

This attribute is read-only, accepts C<(InstanceOf["FlightRecorder"])> values, and is optional.

=cut

=head2 repo

  repo(Object)

This attribute is read-only, accepts C<(Object)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 debug

  debug(Str @args) : Any

The debug method proxies to L<FlightRecorder/debug> via the C<handler>
attribute.

=over 4

=item debug example #1

  # given: synopsis

  $log->debug('debug message');

=back

=cut

=head2 fatal

  fatal(Str @args) : Any

The fatal method proxies to L<FlightRecorder/fatal> via the C<handler>
attribute.

=over 4

=item fatal example #1

  # given: synopsis

  $log->fatal('fatal message');

=back

=cut

=head2 info

  info(Str @args) : Any

The info method proxies to L<FlightRecorder/info> via the C<handler> attribute.

=over 4

=item info example #1

  # given: synopsis

  $log->info('info message');

=back

=cut

=head2 output

  output() : Str

The output method proxies to L<FlightRecorder/output> via the C<handler>
attribute.

=over 4

=item output example #1

  # given: synopsis

  $log->info('info message')->output;

=back

=cut

=head2 warn

  warn(Str @args) : Any

The warn method proxies to L<FlightRecorder/warn> the C<handler> attribute.

=over 4

=item warn example #1

  # given: synopsis

  $log->warn('warn message');

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
