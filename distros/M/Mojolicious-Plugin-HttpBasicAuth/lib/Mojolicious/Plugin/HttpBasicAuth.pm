package Mojolicious::Plugin::HttpBasicAuth;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Mojo::Util qw{b64_encode b64_decode};

our $VERSION = '0.12';

sub register {
    my ($plugin, $app, $user_defaults) = @_;

    push @{ $app->renderer->classes }, __PACKAGE__;

    my %defaults = %$user_defaults;
    $defaults{realm} //= 'WWW';
    $defaults{validate} //= sub {
        die('please define a validate callback');
    };
    $defaults{invalid} //= sub {
        my $controller = shift;
        return (
            json => { json     => { error => 'HTTP 401: Unauthorized' } },
            html => { template => 'auth/basic' },
            any  => { data     => 'HTTP 401: Unauthorized' }
        );
    };

    $app->renderer->add_helper(
        basic_auth => sub {
            my $controller = shift;
            my $params     = shift // {};
            my %options    = (%defaults, %$params);

            # Sent credentials
            my $auth = b64_decode($plugin->_auth_header($controller) || '');

            # No credentials entered
            return $plugin->_unauthorized($controller, $options{realm}, $options{invalid}) unless ($auth);

            # Verification within callback
            return 1 if $options{validate} and $options{validate}->($controller, split(/:/, $auth, 2), $options{realm});

            # Not verified
            return $plugin->_unauthorized($controller, $options{realm}, $options{invalid});
        }
    );
}

sub _auth_header {
    my $plugin     = shift;
    my $controller = shift;
    my $auth       = $controller->req->headers->authorization || $controller->req->env->{'X_HTTP_AUTHORIZATION'} || $controller->req->env->{'HTTP_AUTHORIZATION'};

    if ($auth && $auth =~ m/Basic (.*)/) {
        $auth = $1;
    }

    return $auth;
}

sub _unauthorized {
    my ($plugin, $controller, $realm, $callback) = @_;

    $controller->res->code(401);
    $controller->res->headers->www_authenticate("Basic realm=\"$realm\"");
    $controller->respond_to($callback->($controller));

    # Only render if not already rendered
    if ($controller->tx) {
      $controller->rendered;
    }

    return;
}

1;

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::HttpBasicAuth - Http-Basic-Authentication implementation for Mojolicious

=head1 SYNOPSIS

  # in your startup
  $self->plugin(
      'http_basic_auth', {
          validate => sub {
              my $c         = shift;
              my $loginname = shift;
              my $password  = shift;
              my $realm     = shift;
              return 1 if($realm eq 'Evergreen Terrace' && $loginname eq 'Homer' && $password eq 'Marge');
              return 0;
          },
          realm => 'Evergreen Terrace'
      }
  );

  # in your routes
  sub index {
      my $self = shift;
      return unless $self->basic_auth(\%options);
      $self->render();
  }

  # or bridged
  my $foo = $r->bridge('/bridge')->to(cb => sub {
      my $self = shift;
      # Authenticated
      return unless $self->basic_auth({realm => 'Castle Bridge', validate => sub {return 1;}});
  });
  $foo->route('/bar')->to(controller => 'foo', action => 'bar');


=head1 DESCRIPTION

L<Mojolicious::Plugin::HttpBasicAuth> is a implementation of the Http-Basic-Authentication

=head1 OPTIONS

L<Mojolicious::Plugin::HttpBasicAuth> supports the following options.

=head2 realm

  $self->plugin('http_basic_auth', {realm => 'My Castle!'});

HTTP-Realm, defaults to 'WWW'

=head2 validate

  $self->plugin('http_basic_auth', {
      validate => sub {
            my $c          = shift;
            my $loginname  = shift;
            my $password   = shift;
            my $realm      = shift;
            return 1 if($realm eq 'Springfield' && $loginname eq 'Homer' && $password eq 'Marge');
            return 0;
      }
  });

Validation callback to verify user. This option is B<mandatory>.

=head2 invalid

  $self->plugin('http_basic_auth', {
      invalid => sub {
          my $controller = shift;
          return (
              json => { json     => { error => 'HTTP 401: Unauthorized' } },
              html => { template => 'auth/basic' },
              any  => { data     => 'HTTP 401: Unauthorized' }
          );
      }
  });

Callback for invalid requests, default can be seen here. Return values are dispatched to L<Mojolicious::Controller/"respond_to">

=head1 HELPERS

L<Mojolicious::Plugin::HttpBasicAuth> implements the following helpers.

=head2 basic_auth

  return unless $self->basic_auth({realm => 'Kitchen'});

All default options can be overwritten in every call.

=head1 METHODS

L<Mojolicious::Plugin::HttpBasicAuth> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  my $route = $plugin->register(Mojolicious->new);
  my $route = $plugin->register(Mojolicious->new, {realm => 'Fort Knox', validate => sub {
      return 0;
  }});

Register renderer and helper in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Patrick Grämer E<lt>pgraemer@cpan.orgE<gt>
, L<http://graemer.org>.

=head1 CONTRIBUTOR

Markus Michel E<lt>mmichel@cpan.orgE<gt>
, L<http://markusmichel.org>.

=head1 COPYRIGHT

Copyright 2015 Patrick Grämer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

@@ auth/basic.html.ep
<h1>Authorization Required</h1>
<p>This server could not verify that you
are authorized to access the document
requested.  Either you supplied the wrong
credentials (e.g., bad password), or your
browser doesn't understand how to supply
the credentials required.</p>

__END__
