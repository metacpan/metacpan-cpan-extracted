package Mojolicious::Plugin::JSONP;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.04';

sub register {
  my ($self, $app, $conf) = @_;

  $app->helper(
    render_jsonp => sub {
      my ($self, $callback, $ref) = @_;

      # $callback is optional
      $ref = $callback, undef $callback if !defined $ref;

      # use default from plugin conf if callback not specified
      #$callback //= $self->param($conf->{callback});
      $callback = $self->param($conf->{callback}) if !$callback;

      my $method = $self->can('render_to_string') || $self->can('render');

      return $callback
        ?   $self->render(text => $callback . '('
          . $self->$method(json => $ref, partial => 1) . ')')
        : $self->render(json => $ref);
    }
  );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::JSONP - Render JSONP with transparent fallback to JSON

=head1 SYNOPSIS

  plugin JSONP => callback => 'callback_function';

  get '/' => sub {
    shift->render_jsonp({one => 'two'});
  };

  # GET request:
  #  ?callback_function=my_function

  # Response:
  #  my_function({"one":"two"})

=head1 DESCRIPTION

L<Mojolicious::Plugin::JSONP> is a helper for rendering JSONP 
with a transparent fallback to JSON if a callback parameter is not specified.

The B<render_jsonp> helper renders a Perl reference as JSON, wrapped in a supplied callback.
If a callback is not supplied, only the JSON structure is returned.

=head2 Explanation

Given the following configuration:

  plugin JSONP => callback => 'callback_function';

And the following action:

  get '/' {
    shift->render_jsonp({one => 'two'})
  };

And this client (browser) request:

  http://domain.com/?callback_function=my_function

The following is returned:

  my_function({"one":"two"});

If the client request does not specify the expected callback function:

  http://domain.com/  # No parameters specified

Only the JSON is returned:

    {"one":"two"}

I<Optionally>, specify the callback function name in the B<render_jsonp> helper:

  get '/' => sub {
    shift->render_jsonp(callback_function => {one => "two"});
  };

Overriding plugin configuration, the following response is returned:

  callback_function({"one":"two"})

=head1 METHODS

L<Mojolicious::Plugin::JSONP> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
