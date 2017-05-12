package Template::Lace::Factory::InferInitArgsRole;

use Moo::Role;
use Scalar::Util;

has 'fields' => (
  is=>'ro',
  required=>1,
  default=>sub {[]});

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  $args->{fields} = $class->find_fields($args->{model_class});
  return $args;
};

# Might need something better here eventually.  Not sure
# we want to allow to infer any init argument, just the 
# ones aimed to be in the render of the template.  might
# need a 'has_content', 'has_node', etc?

# Please Note obviously this requires Moose

sub find_fields {
  my ($class, $model_class) = @_;
  return map { $_->init_arg } 
    grep { $_->has_init_arg }
    grep { $_->name ne 'ctx' }
    grep { $_->name ne 'catalyst_component_name' }
    ($model_class->meta->get_all_attributes);
}

around 'prepare_args', sub {
  my ($orig, $self, @args) = @_;
  my %args = $self->infer_args_from(@args);
  return $self->$orig(%args);
};

sub infer_args_from {
  my $self = shift;
  my %args = ();
  my @fields = @{$self->fields};

  # If the first argment is an object or a hashref then
  # we inspect it and unroll any matching fields.  This
  # is to allow a more ease of use for the view call (and
  # it enables a few other things ).

  if(Scalar::Util::blessed($_[0])) {
    my $init_object = shift @_;
    %args = map { $_ => $init_object->$_ } 
      grep { $init_object->can($_) }
      @fields;
  }

  return (%args, @_);
}

1;

=head1 NAME

Template::Lace::Factory::InferInitArgsRole - fill init args by inspecting an object

=head1 SYNOPSIS

Create a template class:

   package  MyApp::Template::User;

    use Moo;
    with 'Template::Lace::ModelRole',
    'Template::Lace::Factory::InferInitArgsRole',

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template {q[
      <html>
        <head>
          <title>User Info</title>
        </head>
        <body>
          <dl id='user'>
            <dt>Name</dt>
            <dd id='name'>NAME</dd>
            <dt>Age</dt>
            <dd id='age'>AGE</dd>
            <dt>Motto</dt>
            <dd id='motto'>MOTTO</dd>
          </dl>
        </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
        age=>$self->age,
        name=>$self->name,
        motto=>$self->motto
      });
    }

    1;

Create an object;

    package MyApp::User;

    has [qw/age name motto/] => (is=>'ro', required=>1);

    1;

    my $user = MyApp::User->new(age=>42,name=>'Joe', motto=>'Why?');

Use the object to create a render instance for your template:

    my $factory = Template::Lace::Factory->new(
      model_class=>'MyApp::Template::User');

    my $renderer = $factory->create($user);

    print $renderer->render;

Outputs:

    <html>
      <head>
        <title>
          User Info
        </title>
      </head>
      <body id="body">
        <dl id="user">
          <dt>
            Name
          </dt>
          <dd id="name">
            Joe
          </dd>
          <dt>
            Age
          </dt>
          <dd id="age">
            42
          </dd>
          <dt>
            Motto
          </dt>
          <dd id="motto">
            Why?
          </dd>
        </dl>
      </body>
    </html>

=head1 DESCRIPTION

Allows you to fill your template arguments from an object, possibily saving you some
tedious typing (at the possible expense of understanding).

In the (often likely) case that there is great interface compatibility between your
business objects and template models, this role can save you the effort of writing a lot
of tendious mapping code.  Can save a lot when the interfaces contain a ton of fields.
However you are reducing possible comprehension as well as introducing a possible evil
interface binding into your code.  The choice is yours :)

B<NOTE> This works by using L<Moose> and assumes your classes are written with L<Moo>
or L<Moose>.  This means you are adding a dependency on L<Moose> into your project
that you may not want.  You will also inflate a meta object on your L<Moo> class which
may have some performance and memory usage implications.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
