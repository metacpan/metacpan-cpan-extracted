package Stencil::Source::Class;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

extends 'Stencil::Source';

our $VERSION = '0.03'; # VERSION

1;


=encoding utf8

=head1 NAME

Stencil::Source::Class

=cut

=head1 ABSTRACT

Perl 5 class source code generator

=cut

=head1 SYNOPSIS

  use Stencil::Source::Class;

  my $source = Stencil::Source::Class->new;

=cut

=head1 DESCRIPTION

This package provides a Perl 5 class source code generator, using this
specification.

  # package name
  name: MyApp

  # package inheritence
  inherits:
  - MyApp::Parent

  # package roles
  integrates:
  - MyApp::Role::Doable

  # package attributes
  attributes:
  - is: ro
    name: name
    type: Str
    required: 1

  # generator operations
  operations:
  - from: class
    make: lib/MyApp.pm
  - from: class-test
    make: t/MyApp.t

  # package functions
  functions:
  - name: execute
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  # package methods
  methods:
  - name: execute
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  # package routines
  routines:
  - name: execute
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
file"|https://github.com/iamalnewkirk/stencil/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/stencil/wiki>

L<Project|https://github.com/iamalnewkirk/stencil>

L<Initiatives|https://github.com/iamalnewkirk/stencil/projects>

L<Milestones|https://github.com/iamalnewkirk/stencil/milestones>

L<Contributing|https://github.com/iamalnewkirk/stencil/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/stencil/issues>

=cut
__DATA__

@=spec

name: MyApp

inherits:
- MyApp::Parent

integrates:
- MyApp::Role::Doable

attributes:
- is: ro
  name: name
  type: Str
  required: 1

operations:
- from: class
  make: lib/MyApp.pm
- from: class-test
  make: t/MyApp.t

routines:
- name: execute
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

@=class

package [% data.name %];

use 5.014;

use strict;
use warnings;

use Moo;

[%- IF data.inherits %]
[%- FOR item IN data.inherits %]
extends '[% item %]';
[%- END %]
[% END -%]

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
  required => [% item.required %],
);
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

@=class-test

use 5.014;

use strict;
use warnings;

use Test::More;

use_ok '[% data.name %]';

[%- IF data.inherits %]
[%- FOR item IN data.inherits %]
isa_ok '[% data.name %]', '[% item %]';
[%- END %]
[% END -%]

[%- IF data.integrates %]
[%- FOR item IN data.integrates %]
use_ok '[% item %]';
[%- END %]
[% END -%]

subtest 'synopsis', sub {

  # do something ...

};

[%- IF data.routines %]
[%- FOR item IN data.routines %]
subtest 'routine: [% item.name %]', sub {

  # do something ...

};
[% END -%]
[% END -%]

done_testing;
