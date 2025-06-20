package Reactive::Mojo::TemplateRenderer;

use warnings;
use strict;

use Moo;
use namespace::clean;
use Types::Standard qw(InstanceOf);

use Mojo::ByteStream qw(b);
use Mojo::Util qw(xml_escape);

extends 'Reactive::Core::TemplateRenderer';

=head2 app($self)
    This method is not expected to be called directly via userland code
    it is set by Reactive::Mojo::Plugin and used to access some features of
    Mojolicious such as the template processing
=cut
has app => (is => 'ro', isa => InstanceOf['Mojolicious']);
has controller => (is => 'lazy', isa => InstanceOf['Mojolicious::Controller']);

=head2 render($self, $type, $template, %properties)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core->_to_snapshot
=cut
sub render {
    my $self = shift;
    my $type = shift;
    my $template = shift;
    my %properties = @_;

    my $arg = lc $type;
    if ($arg eq 'file') {
        $arg = 'template';
    }

    return $self->controller->render_to_string($arg => $template, %properties);
}

=head2 escape($self, $string)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core::TemplateRenderer->inject_attribute
=cut
sub escape {
    my $self = shift;
    my $string = shift;

    return xml_escape($string);
}

=head2 inject_attribute($self, $html, $attribute, $value)
    This method is not expected to be called directly via userland code
    but instead will be called by Reactive::Core::TemplateRenderer->inject_snapshot
=cut
sub inject_attribute {
    my $self = shift;
    my $html = shift;
    my $attribute = shift;
    my $value = shift;

    my $result = $self->SUPER::inject_attribute($html, $attribute, $value);

    return b($result);
}

sub _build_controller {
    my $self = shift;

    return $self->app->build_controller;
}

1;
