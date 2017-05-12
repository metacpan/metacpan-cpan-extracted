## no critic (Moose::RequireMakeImmutable)
package MooseX::MojoControllerExposingAttributes;

use strict;
use warnings;

# ensure loaded, even but don't have the side effects on this class
use Moose            ();
use MooseX::NonMoose ();

# modules we use ourselves
use Moose::Exporter;
use MooseX::MojoControllerExposingAttributes::Trait::Attribute;
use MooseX::MojoControllerExposingAttributes::Trait::Class;
use Import::Into;

our $VERSION = '1.000001';

my $baseclass = 'Mojolicious::Controller';

# While the unimport / init_meta installation this creates is fine to install
# directly, we need a customer importer

my ($import) = Moose::Exporter->build_import_methods(

    # give the class the role that has the 'controller_method_name' method in it
    base_class_roles =>
        ['MooseX::MojoControllerExposingAttributes::Role::Class'],

    # this allows the meta class to have 'get_attribute_for_mojo_helper' which
    # is used by 'controller_method_name' to do the lookup
    class_metaroles => {
        class => ['MooseX::MojoControllerExposingAttributes::Trait::Class'],
    },

    install => [qw(unimport init_meta)],
);

sub import {
    my $target = caller;

    # do the Moose/NonMoose dance
    # TODO, shouldn't we do something with unimport also so we can "no Moose" ?
    MooseX::NonMoose->import::into($target);
    Moose->import::into($target);

    # set the baseclass
    # this must happen AFTER we've moosified the package, but BEFORE the
    # M::E import routine monkeys around with the metaclass (a side effect
    # of how MooseX::NonMoose does its magic)
    $target->meta->superclasses($baseclass);

    # now do the normal import
    goto &$import;
}

1;

# ABSTRACT: Expose controller attributes to Mojolicious

__END__

=pod

=head1 NAME

MooseX::MojoControllerExposingAttributes - Expose controller attributes to Mojolicious

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

    package MyApp::Controller::Example;
    use MooseX::MojoControllerExposingAttributes;

    ...;

    has some_attribute => (
        is     => 'ro',
        traits => ['ExposeMojo'],
    );

    # then later in a template: <%= ctrl->some_attribute %>

=head1 DESCRIPTION

This module is for advanced use.  C<$c>/C<$self> are already made available in
templates and are likely sufficient for the majority of use cases.  This module
was created in order to expose L<Moose> attributes in a way where you don't
have to stash them every single time you want to use them.

This class allows you to expose I<selected> Moose attributes from your
Mojolicious controller to your templates by marking them with the C<ExposeMojo>
trait.

Using this class in a Perl class does several things:

=over

=item It makes the class a subclass of Mojolicious::Controller

=item It sets up the class with Moose and Moose::NonMoose

=item It applies the extra role and metaclass traits to the class so this works with L<Mojolicious::Plugin::ExposeControllerMethod>

=item It sets up the C<ExposeMojo> trait

=back

So rather than declaring your controller class a Moose Mojolicious Controller in
the usual way:

   package MyApp::Controller::Example;
   use Mojo::Base 'Mojolicious::Controller';
   use Moose::NonMoose;
   use Moose;

You should simply say:

   package MyApp::Controller::Example;
   use MooseX::MojoControllerExposingAttributes;

Once you've done that then you can define attributes in the class (or in roles
the class consumes) that are exposed to Mojolicious.

  has some_attribute => (
      is     => 'ro',
      traits => ['ExposeMojo'],
  );

  has some_attribute_with_a_really_long_name => (
     is                => 'ro',
     traits            => ['ExposeMojo'],
     expose_to_mojo_as => 'shorter_name',
  );

In order to get the C<ctrl> helper you should make sure you've loaded the
L<Mojolicious::Plugin::ExposeControllerMethod> plugin somewhere in your
Mojolicious application, typically within the C<startup> method itself:

    sub startup {
        my $self = shift;

        $self->plugin('ExposeControllerMethod');

        ...
    }

Then you'll be able to access your attributes from within templates that
are rendered from that controller:

   some attribute: <%= ctrl->some_attribute %>
   some attribute with a really long name: <%= ctrl->shorter_name %>

=head1 BUGS

It would be nice to be able to set the baseclass instead of always
using Mojolicious::Controller

=head1 SEE ALSO

L<Mojolicious::Plugin::ExposeControllerMethod>

L<MooseX::MojoControllerExposingAttributes::Trait::Attribute>

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Olaf Alders

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
