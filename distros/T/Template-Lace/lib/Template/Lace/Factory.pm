package Template::Lace::Factory;

use Moo;
use Module::Runtime 'use_module';

sub DOM_CLASS { use_module 'Template::Lace::DOM' }
sub RENDERER_CLASS { use_module 'Template::Lace::Renderer' }
sub COMPONENTS_CLASS { use_module 'Template::Lace::Components' }

has 'model_class' => (
  is=>'ro',
  required=>1);

has 'model_constructor' => (
  is=>'ro',
  required=>0,
  predicate=>'has_model_constructor');

has 'renderer_class' => (
  is=>'ro',
  required=>1,
  default=>sub { RENDERER_CLASS } );

has 'dom' => (
  is=>'ro',
  required=>1);

has 'init_args' => (
  is=>'ro',
  required=>1,
  default=>sub { +{} });

has 'components' => (
  is=>'ro',
  required=>1);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my $model_class = $class->_get_model_class($args);
  my $dom_class = $class->_get_dom_class($args);
  my $components_class = $class->_get_components_class($args);
  my $dom = $args->{dom} = $class->_build_dom($dom_class, $model_class);
  my $component_handlers = $args->{component_handlers};
  $args->{components} = $class->_build_components(
    $components_class,
    $model_class,
    $dom,
    $component_handlers);
  return $args;
};

  sub _get_model_class {
    my ($class, $args) = @_;
    my $model_class = use_module($args->{model_class});
    return $model_class;
  }

  sub _get_dom_class {
    my ($class, $args) = @_;
    my $dom_class = exists $args->{dom_class} ?
      use_module($args->{dom_class}) :
        DOM_CLASS;
    return $dom_class;
  }

  sub _get_components_class {
    my ($class, $args) = @_;
    my $components_class = exists $args->{components_class} ?
      use_module($args->{components_class}) :
        COMPONENTS_CLASS;
    return $components_class;
  }

  sub _build_dom {
    my ($class, $dom_class, $model_class) = @_;
    my $template = $model_class->template;
    my $dom = $dom_class->new($template);
    $model_class->prepare_dom($dom);
    return $dom;
  }

  sub _build_components {
    my ($class, $components_class, $model_class, $dom, $component_handlers) = @_;
    my $components = $components_class->new(
      dom => $dom,
      model_class => $model_class,
      component_handlers => $component_handlers);
    return $components;
  }

sub create {
  my ($self, @args) = @_;
  my %args = $self->prepare_args(@args);
  my $dom = $self->create_dom(%args);
  my $model = $self->create_model(%args);
  my $renderer = $self->create_renderer(
    $model,
    $dom,
    $self->components);
  return $renderer;
}

sub render { 
  my ($self, @args) = @_;
  my $renderer = $self->create(@args);
  my $response = $renderer->render;
  return $response;
}

sub prepare_args {
  my ($self, @args) = @_;
  my %args = (%{$self->init_args}, @args);
  return %args;
}

sub create_dom {
  my ($self, %args) = @_;
  my $dom = $self->dom->clone;
  return $dom;
}

sub create_model {
  my ($self, %args) = @_;
  my $model = $self->has_model_constructor ?
    $self->model_constructor->($self->model_class, %args) :
    $self->model_class->new(%args);
  return $model;
}


sub create_renderer {
  my ($self, $model, $dom, $components) = @_;
  my $renderer = $self->renderer_class->new(
    model=>$model,
    components=>$components,
    dom=>$dom);
  return $renderer;
}

1;

=head1 NAME

Template::Lace::Factory - Create templates

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Produces Templates from a model.

=head1 INITIALIZATION ARGUMENTS

This class defines the following initialization arguments

=head2 model_class

The class that is providing the view model and does the interface
defined by L<Template::Lace::ModelRole>

=head2 model_constructor

An optional codereference that allows you to specify how the C<model_class>
it turned into an instance.  By default we call a method called C<new>
on the C<model_class>.  If you have special needs in creating the model
you can define this coderef which gets the C<model_class> and initialization
arguments and should return an instance.  For example:

    model_constructor => sub {
      my ($model_class, %args) = @_:
      return $model_class->new( version=>1, %args); 
    },

=head2 renderer_class

The name of the Render class.  useful if you need to subclass to provide
special feeatures.

=head2 init_args

A hashref of arguments that are fixed and are always passed to the model
constructor at create time.  Useful if your model class has some attributes
which only need to be defined once.

=head2 component_mappings

A Hashref of component information.  For now see the core documentation at
L<Template::Lace> for details about components.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
