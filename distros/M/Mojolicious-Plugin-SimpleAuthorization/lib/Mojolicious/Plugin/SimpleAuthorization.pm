package Mojolicious::Plugin::SimpleAuthorization;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
  my ($self, $app, $conf) = @_;

  # Default mojo stash values for the user and their roles
  $conf->{roles} //= 'roles';
  $conf->{user}  //= 'user';

  # Hook if assert_user_roles fails
  delete $conf->{on_assert_failure}
    unless ref $conf->{on_assert_failure} eq 'CODE';

  # Add "assert_user_roles" helper
  $app->helper(
    assert_user_roles => sub {
      my $self = shift;

      my $result = $self->check_user_roles(@_);
      if ($result == 0) {
        $conf->{on_assert_failure}->($self, @_)
          if defined $conf->{on_assert_failure};
      }

      return $result;
    }
  );

  # Add "check_user_roles" helper
  $app->helper(
    check_user_roles => sub {
      my $self  = shift;
      my $tests = shift;
      my $cb    = ref $_[-1] eq 'CODE' ? pop : undef;

      my $roles = $self->stash->{$conf->{roles}} // {};
      my $user  = $self->stash->{$conf->{user}}  // {};
      $tests = [$tests] unless ref $tests eq 'ARRAY';

      my $cbresult;
      if ($cb) {
        return 1 if $cbresult = $cb->($user, $roles);
      }

      # An undefired cbresult indicates the authorization chain should continue
      if (not defined $cbresult) {
        # Superuser value for the user hash, or code ref to check if this user
        # has full permission for every role.
        if (defined $conf->{superuser}) {
          if (ref $conf->{superuser} eq 'CODE') {
            return 1 if $conf->{superuser}->($user, $roles);
          }
          else {
            return 1 if $user->{$conf->{superuser}};
          }
        }
        map { return 1 if $roles->{$_} } @$tests;
      }

      return 0;
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::SimpleAuthorization - Simple role-based authorization

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::SimpleAuthorization> is a simple role-based authorization
plugin for L<Mojolicious>.

It attempts to keep a sane control flow by not croaking or dying if the user
does not have the relevant roles/permissions. As such, C<check_user_roles> or
C<assert_user_roles> should be called at the beginning of your controllers.

L<Mojolicious::Plugin::SimpleAuthorization> does offer the hook
C<on_assert_failure> if you want to render a permission denied response or
similar for every request that isn't authorized. (Or if you would prefer to
croak/die.)

=head1 OPTIONS

L<Mojolicious::Plugin::SimpleAuthorization> supports the following options.

=head2 on_assert_failure

  # Mojolicious::Lite
  plugin SimpleAuthorization => {
    on_assert_failure => sub {
      my ($self, $tests) = @_;

      $self->render(
        text => 'You don't have permission to access this resource.');
    }
  };

If assert_user_roles fails to authorize, this code ref is called.

=head2 roles

  # Mojolicious::Lite
  plugin SimpleAuthorization => {roles => 'auth_roles'};

  # In your under or controller
  $self->stash(auth_roles => {'user.delete' => 1, 'user.search' => 1});

Name of stash value which holds all the roles for the current user. Must be a
C<HASHREF>. Defaults to C<roles>.

=head2 superuser

  # Mojolicious::Lite
  plugin SimpleAuthorization => {superuser => 'administrator'};
  plugin SimpleAuthorization => {
    'superuser' => sub {
      my ($user, $roles) = @_;
      return 1 if $user->{administrator};
    }
  };

  $self->check_user_roles([qw/some_random_role/]);    # returns 1
  $self->check_user_roles([qw/crazy_role/]);          # returns 1

Adds the possibility of a superuser - a user that can assume every role.

The above two examples are the same. If the C<administrator> key exists in the
C<user> hash and it evaluates to true, the user will pass every role check. The
C<superuser> CODE example performs an equivalent evaluation.

=head2 user

  # Mojolicious::Lite
  plugin SimpleAuthorization => {user => 'auth_user'};

  # In your under or controller
  $self->stash(auth_user => {username => 'paul.williams', administrator => 0});

Name of stash value which holds the user's information. Must be a C<HASHREF>.
Defaults to C<user>.

=head1 METHODS

L<Mojolicious::Plugin::SimpleAuthorization> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 assert_user_roles

Same as C<check_user_roles>, except it calls the hook C<on_assert_failure> if
the user isn't authorized. Returns a boolean value.

=head2 check_user_roles

  my $assert = $self->check_user_roles('user.create');
  my $assert = $self->check_user_roles([qw/user.editor user.create/]);

Checks the user and returns a boolean value.

  my $user_to_delete = 'admin';
  my $assert = $self->check_user_roles(
    ['user.delete'],
    sub {
      my ($user, $roles) = @_;
      return 0 if $user_to_delete eq 'admin';
    }
  );

Optionally pass a callback to apply your own one-off role check. Useful as in
the example above, where the user 'admin' cannot be deleted.

If the callback returns a positive value, the user is authorized. 0 and the user
is not authorized, undef and the authorization chain continues.

  my $message = get_message_to_delete();
  my $assert = $self->check_user_roles(
    ['message.delete'],
    sub {
      my ($user, $roles) = @_;
      $roles->{'message.delete'}++
        if $message->{username} eq $user->{username};
      return undef;
    }
  );

This technique can also be used to give the user a role based on certain
criteria. In the example above, a user who cannot delete all messages, can
delete their own message.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 HOW TO CONTRIBUTE

Contributions welcome, though this plugin is pretty basic. I currently only
accept GitHub pull requests.

=over

=item * GitHub: L<https://github.com/kwakwaversal/mojolicious-plugin-simpleauthorization>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015, Paul Williams.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Paul Williams <kwakwa@cpan.org>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::Authorization>.

=cut
