package MooseX::Templated;

use MooseX::Role::Parameterized;
use MooseX::Templated::Engine;
use MooseX::Types::Path::Class qw/ Dir /;
use Path::Class;
use namespace::autoclean;

our $VERSION = '0.09';

parameter view_class => (
  is => 'ro',
  isa => 'Str',
  default => 'MooseX::Templated::View::TT',
);

parameter template_method_stub => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_template_method_stub',
);

parameter template_suffix => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_template_suffix',
);

parameter template_root => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  predicate => 'has_template_root',
);

role {
  my $p = shift;

  has 'template_engine' => ( # class_has ?
    is => 'ro',
    isa => 'MooseX::Templated::Engine',
    lazy => 1,
    builder => '_build_template_engine',
    handles => [ 'render' ],
  );

  method "_build_template_engine" => sub {
    my $self = shift;
    my $engine = MooseX::Templated::Engine->new(
      ( $p->has_template_method_stub ? ( template_method_stub => $p->template_method_stub ) : () ),
      ( $p->has_template_suffix      ? ( template_suffix      => $p->template_suffix ) : () ),
      ( $p->has_template_root        ? ( template_root        => $p->template_root ) : () ),
      view_class           => $p->view_class,
      model                => $self,
    );
    return $engine;
  };

  method "render" => sub {
    my $self = shift;
    return $self->template_engine->render( @_ );
  };

};


1;

__END__

=head1 NAME

MooseX::Templated - template-based rendering of Moose objects

=head1 SYNOPSIS

    package Farm::Cow;

    use Moose;

    with 'MooseX::Templated';

    has 'spots'   => ( is => 'rw' );
    has 'hobbies' => ( is => 'rw', default => sub { ['mooing', 'chewing'] } );

    sub make_a_happy_noise { "Mooooooo" }

Specify template:

    sub _template { <<'_TT2' }

    This cow has [% self.spots %] spots - it likes
    [% self.hobbies.join(" and ") %].
    [% self.make_a_happy_noise %]!

    _TT2

Or as a separate file:

    # lib/Farm/Cow.tt

Render the object:

    $cow = Farm::Cow->new( spots => '8' );

    print $cow->render();

    # This cow has 8 spots - it likes
    # mooing and chewing.
    # Mooooooo!

Provide options (such as default file location):

    # lib/Farm/Cow.pm

    with 'MooseX::Templated' => {
      template_suffix => '.tt2',
      template_root   => '__LIB__/../root',
    };

    # now looks for
    # root/Farm/Cow.tt2

=head1 DESCRIPTION

The C<MooseX::Templated> role provides the consuming class with a method
C<render()> which allows template-based rendering of the object.

=head1 METHODS

The following methods are provided to the consuming class

=head2 template_engine

Returns L<MooseX::Template::Engine> which is the templating engine responsible
for rendering the template.

=head2 render

Finds the template source, performs the rendering, returns
the rendered result as a string.

Note: the location of the template source is affected by (optional) arguments
and role configuration (see below for details).

=head1 TEMPLATE SOURCE

The template engine will search for the template source in a few different
locations: files, methods, inline.

  Farm::Cow->new()->render()

=head3 File system

This will look for a template file that relates to the calling package. With
default settings, the above example would look for:

  __LIB__/Farm/Cow.tt

Where C<__LIB__> is the root directory for the modules.

The file path can be affected by configuration options: C<template_root>,
C<template_suffix>

=head3 Local method in code

Define a local method within the calling package which returns the template
source as a string. With default settings, this will look for the method
C<"_template">, e.g.

  sub Farm::Cow::_template { ... }

The expected method name is affected by configuration option: C<template_method_stub>.

=head3 Inline

Provide the template source directly to the render function (as a reference
to the template string).

  Farm::Cow->render( \"Cow goes [% self.moo %]!" );

=head1 CONFIGURATION

Defaults about how to find your template files / methods can be provided at
role composition:

  with 'MooseX::Templated' => {
    view_class           => 'MooseX::Templated::View::TT',
    template_suffix      => '.tt',
    template_root        => '__LIB__',
    template_method_stub => '_template',
  };

=head2 view_class

The class name of the particular template framework being used.

=head2 template_suffix

Override the suffix used for the template files (the default is provided by the C<view_class>)

=head2 template_root

Override the location where the template files are found. The
string "__LIB__" will be replaced by the location of the installed modules, e.g.

  template_root => '__LIB__/../root'

=head2 template_method_stub

Override the method name to use when specifying the template source with a local
method.

See L<MooseX::Templated::Engine> and L<MooseX::Templated::View> for more information

=head1 SEE ALSO

L<Moose>, L<Template>

=head1 REPOSITORY

L<https://github.com/sillitoe/moosex-templated>

=head1 ACKNOWLEDGEMENTS

Chris Prather (perigrin)

=head1 AUTHOR

Ian Sillitoe  C<< <isillitoe@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Ian Sillitoe C<< <isillitoe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
