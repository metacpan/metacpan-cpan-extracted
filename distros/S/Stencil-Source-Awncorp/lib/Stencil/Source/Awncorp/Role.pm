package Stencil::Source::Awncorp::Role;

use 5.014;

use strict;
use warnings;

use Data::Object::Class;

extends 'Stencil::Source';

our $VERSION = '0.01'; # VERSION

1;



=encoding utf8

=head1 NAME

Stencil::Source::Awncorp::Role

=cut

=head1 ABSTRACT

Stencil Generator for Roles

=cut

=head1 SYNOPSIS

  use Stencil::Source::Awncorp::Role;

  my $s = Stencil::Source::Awncorp::Role->new;

=cut

=head1 DESCRIPTION

This package provides a L<Stencil> generator for L<Data::Object::Role> based
roles and L<Test::Auto> tests. This generator produces the following specification:

  name: MyApp
  desc: Doing One Thing Very Well

  libraries:
  - MyApp::Types

  integrates:
  - MyApp::Role::Doable

  attributes:
  - is: ro
    name: name
    type: Str
    form: req

  operations:
  - from: role
    make: lib/MyApp.pm
  - from: role-test
    make: t/MyApp.t

  scenarios:
  - name: exports
    desc: exporting the following functions

  functions:
  - name: handle_a
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  methods:
  - name: handle_b
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  routines:
  - name: handle_c
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Stencil::Source>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/stencil-source-awncorp/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/stencil-source-awncorp/wiki>

L<Project|https://github.com/iamalnewkirk/stencil-source-awncorp>

L<Initiatives|https://github.com/iamalnewkirk/stencil-source-awncorp/projects>

L<Milestones|https://github.com/iamalnewkirk/stencil-source-awncorp/milestones>

L<Contributing|https://github.com/iamalnewkirk/stencil-source-awncorp/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/stencil-source-awncorp/issues>

=cut

__DATA__

@=spec

name: MyApp
desc: Doing One Thing Very Well

libraries:
- MyApp::Types

integrates:
- MyApp::Role::Doable

attributes:
- is: ro
  name: name
  type: Str
  form: req

operations:
- from: role
  make: lib/MyApp.pm
- from: role-test
  make: t/MyApp.t

scenarios:
- name: exports
  desc: exporting the following functions

functions:
- name: handle_a
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

methods:
- name: handle_b
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

routines:
- name: handle_c
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

@=role

package [% data.name %];

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;

[%- IF data.integrates %]
[%- FOR item IN data.integrates %]
with '[% item %]';
[%- END %]
[% END -%]

# VERSION

[%- IF data.attributes %]
# ATTRIBUTES
[% FOR item IN data.attributes %]
has '[% item.name %]' => (
  is => '[% item.is %]',
  isa => '[% item.type %]',
  [% item.form %] => 1,
);
[% END -%]
[% END -%]

[%- IF data.functions %]
# FUNCTIONS
[% FOR item IN data.functions %]
fun [% item.name %]() {
  # do something ...

  return;
}
[% END -%]
[% END -%]

[%- IF data.methods %]
# METHODS
[% FOR item IN data.methods %]
method [% item.name %]() {
  # do something ...

  return $self;
}
[% END -%]
[% END -%]

[%- IF data.routines %]
# ROUTINES
[% FOR item IN data.routines %]
sub [% item.name %] {
  my ($self) = @_;

  # do something ...

  return $self;
}
[% END -%]
[% END -%]

1;

@=role-test

use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

+=name

[% data.name %]

+=cut

+=abstract

[% data.desc %]

+=cut

[%- IF data.functions || data.methods || data.routines %]
+=includes

[%- IF data.functions %]
[%- FOR item IN data.functions %]
function: [% item.name %]
[%- END -%]
[% END %]
[%- IF data.methods %]
[%- FOR item IN data.methods %]
method: [% item.name %]
[%- END -%]
[% END %]
[%- IF data.routines %]
[%- FOR item IN data.routines %]
routine: [% item.name %]
[%- END -%]
[% END %]

+=cut
[% END -%]

+=synopsis

  use [% data.name %];

  # do something ...

+=cut

[%- IF data.libraries %]
+=libraries

[%- FOR item IN data.libraries %]
[% item %]
[%- END %]

+=cut
[% END -%]

[%- IF data.integrates %]
+=integrates

[%- FOR item IN data.integrates %]
[% item %]
[%- END %]

+=cut
[% END -%]

[%- IF data.attributes %]
+=attributes

[%- FOR item IN data.attributes %]
[% item.name %]: [% item.is %], [% item.form %], [% item.type %]
[%- END %]

+=cut
[% END -%]

+=description

This package provides [% data.desc %].

+=cut

[%- IF data.scenarios %]
[%- FOR item IN data.scenarios %]
+=scenario [% item.name %]

This package supports [% item.desc %].

+=example [% item.name %]

  use [% data.name %];

  # do something ...

+=cut
[% END -%]
[% END -%]

[%- IF data.functions %]
[%- FOR item IN data.functions %]
+=function [% item.name %]

The [% item.name %] method [% item.desc %].

+=signature [% item.name %]

[% item.name %][% item.args %]

+=example-1 [% item.name %]

  # given: synopsis

  # do something ...

+=cut
[% END -%]
[% END -%]

[%- IF data.methods %]
[%- FOR item IN data.methods %]
+=method [% item.name %]

The [% item.name %] method [% item.desc %].

+=signature [% item.name %]

[% item.name %][% item.args %]

+=example-1 [% item.name %]

  # given: synopsis

  # do something ...

+=cut
[% END -%]
[% END -%]

[%- IF data.routines %]
[%- FOR item IN data.routines %]
+=method [% item.name %]

The [% item.name %] method [% item.desc %].

+=signature [% item.name %]

[% item.name %][% item.args %]

+=example-1 [% item.name %]

  # given: synopsis

  # do something ...

+=cut
[% END -%]
[% END -%]

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

[%- IF data.scenarios %]
[%- FOR item IN data.scenarios %]
$subs->scenario('[% item.name %]', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});
[% END -%]
[% END -%]

[%- IF data.functions %]
[%- FOR item IN data.functions %]
$subs->example(-1, '[% item.name %]', 'function', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});
[% END -%]
[% END -%]

[%- IF data.methods %]
[%- FOR item IN data.methods %]
$subs->example(-1, '[% item.name %]', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});
[% END -%]
[% END -%]

[%- IF data.routines %]
[%- FOR item IN data.routines %]
$subs->example(-1, '[% item.name %]', 'routine', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});
[% END -%]
[% END -%]

ok 1 and done_testing;