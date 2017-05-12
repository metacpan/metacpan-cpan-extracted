package Mojolicious::Plugin::Parallol;

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util 'weaken';
use Carp;

sub register {
  my ($plugin, $app) = @_;

  $app->helper(on_parallol => sub {
    my $p = shift->stash('parallol');
    carp "Can't call on_parallol outside of Parallol" unless $p;

    # Setter.
    return $p->{done} = shift if @_;

    # Getter w/ default.
    return $p->{done} ||= sub {
      my $self = shift;
      $self->render unless $self->stash('mojo.finished');
    }
  });

  $app->hook(around_dispatch => sub {
    my ($next, $self) = @_;

    my $p = {};
    $self->stash(parallol => $p);

    # This number represents the number of pending calls (that is, calls
    # that have been done, but the callback hasn't been called yet).
    # Every time this number gets decremented to zero, you must also
    # call $self->on_parallol->($self) to signal that everything is
    # done.
    # 
    # This number starts at 1 because we consider the action itself a
    # pending call.
    $p->{paralloling} = 1;

    # Call action.
    $next->();

    # If the action didn't call $self->parallol, don't do anything more.
    return unless $p->{paralloled};

    # The action is now done. As mentioned above, we must call
    # on_parallol if there's nothing left to do.
    return $self->on_parallol->($self) if --$p->{paralloling} == 0;

    # If the IO loop is not running  ...
    return if Mojo::IOLoop->is_running;

    # ... we want to run the IO loop and stop it again when it's done.
    my $cb = $self->on_parallol;
    $self->on_parallol(sub {
      # Run the callback; capture any errors.
      eval { $cb->(@_); 1 } or my $e = $@;
      Mojo::IOLoop->stop;
      # Re-throw the error.
      die $e if $e;
    });
    
    Mojo::IOLoop->start;
  });
  
  $app->helper(
    parallol => sub {
      my $callback = pop;
      my ($self, %opts) = @_;
      my $p = $self->stash('parallol');

      if (ref $callback && ref $callback eq 'CODE') {
        weaken($self) if $opts{weaken} // 1;
      } else {
        my $name = $callback;
        $callback = sub { $self->stash($name => pop) }
      }

      # Mark the request as async and paralloled.
      $self->render_later;
      $p->{paralloled} = 1;

      # Increment pending calls.
      $p->{paralloling}++;


      sub {
        # Run the callback.
        eval { $callback->(@_); 1 } or $self->render_exception($@);

        # Run on_parallol if it's finished.
        if (--$p->{paralloling} == 0) {
          eval { $self->on_parallol->($self); 1 } or $self->render_exception($@);
        }
      }
    }
  );
}

"Parallolololololololololol";

__END__

=head1 NAME

Mojolicious::Plugin::Parallol - Because parallel requests should be as
fun as parallololololol!

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Parallol');

  # Mojolicious::Lite
  plugin 'Parallol';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Parallol> provides a simple helper for managing
several parallel requests in the controller.

=head1 HELPERS

L<Mojolicious::Plugin::Parallol> implements the following helpers.

=head2 C<parallol>

Parallol optimizes for the common case: You want to call several
parallel requests and render the view when they're done.

  get '/' => sub {
    my $self = shift;

    $self->ua->get('http://bbc.co.uk/', $self->parallol(sub {
      $self->stash(bbc => pop->res->dom->at('title')->text);
    }));

    $self->ua->get('http://mojolicio.us/', $self->parallol(sub {
      $self->stash(mojo => pop->res->dom->at('title')->text);
    }));
  };

By wrapping a callback in C<< $self->parallol >> you mark the current
response as asynchronous (see L<Mojolicious::Controller/"render_later">)
and Parallol will render the view when all callbacks are called.

=head3 Automatic stashing

By passing a string to C<< $self->parallol >> it will stash the last
argument of the result instead. If we rewrite the previous example to
use a helper, we can simplify our controller quite a lot.

  get '/' => sub {
    my $self = shift;

    $self->title('http://bbc.co.uk/',    $self->parallol('bbc'));
    $self->title('http://mojolicio.us/', $self->parallol('mojo'));
  };

  helper title => sub {
    my ($self, $url, $cb) = @_;
    $self->ua->get($url, sub {
      $cb->(pop->res->dom->at('title')->text);
    });
  };

It's recommended that you move as much logic to helpers and other
classes/methods so you can take advantage of automatic stashing.

=head3 Overriding "done" behavior

When you need to do more than just rendering the view you can override
the "done" callback:

  get '/' => sub {
    my $self = shift;
    $self->on_parallol(sub {
      shift->render(template => 'something_else');
    });
  };

=head3 PSGI support

If the Mojo IO loop is not running, Parallol will automatically start it
for your request, and stop it again when all callbacks have been called.
This means that asynchronous requests just works when you use Parallol
in servers that don't use Mojo's IO loop (PSGI).

=head3 $self weakening

In order to prevent memory leaks, Parallol will automatically C<weaken
$self>. This means that if you I<don't> refer to C<$self> in your
callback objects will magically disappear.

  # This controller will behave very strangely:
  get '/' => sub {
    my $self = shift;
    my $res = {};
    $self->ua->get('http://bbc.co.uk/', $self->parallol(sub {
      # There's no reference to $self in this block
      $res->{bbc} = pop->res->dom->at('title')->text;
    }));
  };

In these cases you can disabled weakening by passing in
C<< weaken => 0 >>.

  # This controller is fine:
  get '/' => sub {
    my $self = shift;
    my $res = {};
    $self->ua->get('http://bbc.co.uk/', $self->parallol(weaken => 0, sub {
      # There's no reference to $self in this block
      $res->{bbc} = pop->res->dom->at('title')->text;
    }));
  };

=head1 METHODS

L<Mojolicious::Plugin::Parrallol> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Parallol>

=head2 AUTHOR

Magnus Holm L<mailto:magnus@nordaaker.com>

=head2 LICENSE

This software is licensed under the same terms as Perl itself.

=cut
