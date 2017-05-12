# Mojolicious::Plugin::SimpleAuthorization [![Build Status](https://travis-ci.org/kwakwaversal/mojolicious-plugin-simpleauthorization.svg?branch=master)](https://travis-ci.org/kwakwaversal/mojolicious-plugin-restify)

Simple role-based authorization for the [Mojolicious](http://mojolicio.us) web
framework

```perl
  # Mojolicious example
  package SimpleApp;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;

    $self->plugin(
      'SimpleAuthorization' => {
        'on_assert_failure' => sub {    # assert failure hook
          my ($self, $tests) = @_;

          $self->render(text => 'Permission denied.');
        },
      }
    );

    # Add route not requiring authentication/authorization
    my $r = $self->routes;
    $r->get('/')->to(cb => sub { shift->render(text => "I am public. Hi.") });

    # Add authentication under (which populates stash with the user/roles)
    #
    # In your under, set the user and user's roles C<HASHREF> every request.
    # The user can contain any arbitrary data. Roles should contain key/value
    # pairs, where allocated roles evaluate to true.
    my $auth = $r->under->to(
      cb => sub {
        my $self = shift;

        #if ($user_is_authenticated) {
          $self->stash(roles => {'user.delete' => 0, 'user.search' => 1});
          $self->stash(user => {username => 'paul', administrator => 0});
        #}
      }
    );

    # Search user controller - success!
    $auth->get('/user/search')->to(
      cb => sub {
        my $self = shift;
        return unless $self->assert_user_roles([qw/user.search/]);

        $self->render(text => "Success! Let's do some searching!");
      }
    );

    # Delete user controller - oh noes! (Will execute C<on_assert_failure>.)
    $auth->get('/user/delete')->to(
      cb => sub {
        my $self = shift;
        return unless $self->assert_user_roles([qw/user.delete/]);

        $self->render(text => "Damn! Not authorized so won't see this!");
      }
    );
  }

  1;
```

[Mojolicious::Plugin::SimpleAuthorization](https://metacpan.org/release/Mojolicious-Plugin-SimpleAuthorization)
is a simple role-based authorization plugin for
[Mojolicious](http://mojolicio.us).

It attempts to keep a sane control flow by not croaking or dying if the user
does not have the relevant roles/permissions. As such, `check_user_roles` or
`assert_user_roles` should be called at the beginning of your controllers.

[Mojolicious::Plugin::SimpleAuthorization](https://metacpan.org/release/Mojolicious-Plugin-SimpleAuthorization)
does offer the hook `on_assert_failure` if you want to render a permission
denied response or similar for every request that isn't authorized. (Or if you
would prefer to croak/die.)
