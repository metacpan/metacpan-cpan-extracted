package Mojolicious::Plugin::ParamExpand;

use Mojo::Base 'Mojolicious::Plugin';
use CGI::Expand;

our $VERSION = '0.03';

sub register
{
  my ($self, $app, $config) = @_;
  my $class = 'Mojolicious::Plugin::ParamExpand::expander';

  _make_package($class, $config);

  $app->hook(before_dispatch => sub {
      my $c = shift;
      my $hash;

      eval { $hash = $class->expand_hash($c->req->params->to_hash) };
      if($@) {
	  # Mojolicious < 6.0 uses render_exception
	  if($c->can('render_exception')) {
	    $c->render_exception($@);
	  }
	  else {
	    $c->reply->exception($@);
	  }

	  return;
      }

      $c->param($_ => $hash->{$_}) for keys %$hash;
  });
}

sub _make_package
{
    no strict 'refs';

    my ($class, $config) = @_;
    @{"${class}::ISA"} = 'CGI::Expand';

    for(qw|max_array separator|) {
        my $val = $config->{$_};
        *{"${class}::$_"} = sub { $val } if defined $val;
    }
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::ParamExpand - Use objects and data structures in your forms

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('ParamExpand', %options);

  # Mojolicious::Lite
  plugin 'ParamExpand', %options;

  # In your action
  sub action
  {
      my $self = shift;
      my $order = $self->param('order');
      $order->{address};
      $order->{items}->[0]->{id};
      $order->{items}->[0]->{price};
      # ...
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::ParamExpand> turns request parameters into nested data
structures using L<CGI::Expand>.

=head1 MOJOLICIOUS VERSION

=head2 Less than 2.52

Due to the old way C<Mojolicious::Controller> handled multi-valued request parameters
versions prior to 2.52 will not work with this plugin. If this is a problem for
you try L<Mojolicious::Plugin::GroupedParams>.

=head2 Greater than 5.57

L<Mojolicious::Controller/param> no longer returns an array.
You must call L<Mojolicious::Controller/every_param>.

=head1 OPTIONS

Options must be specified when loading the plugin.

=head2 separator

  $self->plugin('ParamExpand', separator => ',')

The character used to separate the data structure's hierarchy in the
flattened parameter. Defaults to C<'.'>.

=head2 max_array

  $self->plugin('ParamExpand', max_array => 10)

Maximum number of array elements C<CGI::Expand> will create.
Defaults to C<100>. If a parameter contains more than C<max_array>
elements an exception will be raised.

To force the array into a hash keyed by its indexes set this to C<0>.

=head1 Methods

=head2 param

This is just L<Mojolicious::Controller/param> but, when using C<Mojolicious::Plugin::ParamExpand>, a
request with the parameters

  users.0.name=nameA&users.1.name=nameB&id=123

will return a nested data structure for the param C<'users'>

  @users = $self->param('users');
  $users[0]->{name};
  $users[1]->{name};

Other parameters can be accessed as usual

  $id = $self->param('id');

The flattened parameter name can also be used

  $name0 = $self->param('users.0.name');

=head3 Arguments

C<$name>

The name of the parameter.

=head3 Returns

The value for the given parameter. If applicable it will be an expanded
data structure.

Top level arrays will be returned as arrays B<not> as array references.
This is how C<Mojolicious> behaves. In other words

  users.0=userA&users.1=userB

is equivlent to

  users=userA&users=userB

If this is undesirable you could L<< set C<max_array> to zero|/max_array >>.

=head1 SEE ALSO

L<CGI::Expand>, L<Mojolicious::Plugin::FormFields>, L<Mojolicious::Plugin::GroupedParams>
