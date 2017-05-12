package MooseX::MojoControllerExposingAttributes::Trait::Attribute;
use Moose::Role;
Moose::Util::meta_attribute_alias('ExposeMojo');

our $VERSION = '1.000001';

use MooseX::Types::Moose qw( Str );

has expose_to_mojo_as => (
    is  => 'ro',
    isa => Str,    # todo, this should be a method name constraint
);

no Moose::Role;
1;
__END__

=head1 NAME

MooseX::MojoControllerExposingAttributes::Trait::Attribute - trait used to expose attribute to Mojolicious

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

This class is an attribute trait that can be applied with C<ExposeMojo>.

Applying this trait to an attribute within a L<Mojolicious::Controller> subclass
allows reading of that attribute from within a Mojolicious template by calling
the corresponding method name on the C<ctrl> helper.

In order to this to work you must also correctly setup the metaclass of the
controller (usually by simply doing a
C<use MooseX::MojoControllerExposingAttributes;> within that controller class)
and load the L<Mojolicious::Plugin::ExposeControllerMethod> plugin within your
Mojolicious application to provide the C<ctrl> helper.

=head1 ATTRIBUTES

=head2 expose_to_mojo_as

Provide an alternative name this attribute should be exposed as

    # expose the rose attribute so it can be called via ctrl->other_name
    # rather than ctrl->rose
    has rose => (
        is                => 'ro',
        traits            => ['ExposeMojo'],
        expose_to_mojo_as => 'other_name',
    );

By default if C<expose_to_mojo_as> isn't provided the attribute will be exposed
as a method with the same name as the attribute (worth noting: this is not
necessarily the same as the name of the reader method that you'd normally use to
access the attribute if you've defined that to be different to the attribute
name.)

=head1 SEE ALSO

L<Mojolicious::Plugin::ExposeControllerMethod>

L<MooseX::MojoControllerExposingAttributes>
