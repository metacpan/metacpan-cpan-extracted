package PlugAuth::Routes;

# ABSTRACT: routes for plugauth
our $VERSION = '0.39'; # VERSION


# There may be external authentication for these routes, i.e. using
# this CI to determine who can check/update other's access.

use strict;
use warnings;
use Log::Log4perl qw/:easy/;
use Mojo::ByteStream qw/b/;
use Clustericious::RouteBuilder;
use Clustericious::Config;
use List::Util qw( uniq );


get '/'      => sub { shift->welcome } => 'index';
get '/index' => sub { shift->welcome };


# Check authentication for a user (http basic auth protocol).
get '/auth' => sub {
  my $self = shift;
  my $auth = $self->req->headers->authorization or do {
    $self->res->headers->www_authenticate('Basic "ACPS"');
    $self->render_message('please authenticate', 401);
    return;
  };
  my ($method,$str) = split / /,$auth;
  my ($user,$pw) = split /:/, b($str)->b64_decode;

  if($self->auth->check_credentials($user,$pw))
  {
    $self->render_message('ok');
    INFO "Authentication succeeded for user $user";
  }
  else
  {
    $self->render_message('not ok', 403);
    INFO "Authentication failed for user $user";
  }
};


# Check authorization for a user to perform $action on $resource.
get '/authz/user/#user/#action/(*resource)' => { resource => '/' } => sub {
  my $c = shift;
  # Ok iff the user is in a group for which $action on $resource is allowed.
  my ($user,$resource,$action) = map $c->stash($_), qw/user resource action/;
  $resource =~ s{^/?}{/};
  TRACE "Checking authorization for $user to perform $action on $resource...";
  my $found = $c->authz->can_user_action_resource($user,$action,$resource);
  if ($found)
  {
    TRACE "Authorization succeeded ($found)";
    return $c->render_message('ok');
  }
  TRACE "Authorization failed";
  $c->render_message("unauthorized : $user cannot $action $resource", 403);
};


# Given a user, an action and a regex, return a list of resources
# on which $user can do $action, where each resource matches that regex.
get '/authz/resources/#user/#action/(*resourceregex)' => sub  {
  my $c = shift;
  my ($user,$action,$resourceregex) = map $c->stash($_), qw/user action resourceregex/;
  TRACE "Checking $user, $action, $resourceregex";
  $resourceregex = qr[$resourceregex];
  my @resources;
  for my $resource ($c->authz->match_resources($resourceregex))
  {
    TRACE "Checking resource $resource";
    push @resources, $resource if $c->authz->can_user_action_resource($user,$action,$resource);
  }
  $c->stash->{autodata} = [sort @resources];
};


# Return a list of all defined actions
get '/actions' => sub {
  my($self) = @_;
  $self->stash->{autodata} = [ $self->authz->actions ];
};


# All the groups for a user :
get '/groups/#user' => sub {
  my $c = shift;
  my $groups = $c->authz->groups_for_user($c->stash('user'));
  $c->render_message('not ok', 404) unless defined $groups;
  $c->stash->{autodata} = $groups;
};


# Given a host and a tag (e.g. "trusted") return true if that host has
# that tag.
get '/host/#host/:tag' => sub {
  my $c = shift;
  my ($host,$tag) = map $c->stash($_), qw/host tag/;
  if ($c->authz->host_has_tag($host,$tag))
  {
    TRACE "Host $host has tag $tag";
    return $c->render_message('ok', 200);
  }
  TRACE "Host $host does not have tag $tag";
  return $c->render_message('not ok', 403);
};


get '/user' => sub {
  my $c = shift;
  $c->stash->{autodata} = [ uniq sort $c->auth->all_users ];
};


get '/group' => sub {
  my $c = shift;
  $c->stash->{autodata} = [ $c->authz->all_groups ];
};


get '/users/:group' => sub {
  my $c = shift;
  my $users = $c->authz->users_in_group($c->stash('group'));
  $c->render_message('not ok', 404) unless defined $users;
  $c->stash->{autodata} = $users;
};

authenticate;
authorize 'accounts';


post '/user' => sub {
  my $c = shift;
  $c->parse_autodata;
  my $user     = $c->stash->{autodata}->{user};
  my $password = $c->stash->{autodata}->{password} || '';
  my $groups   = $c->stash->{autodata}->{groups};
  delete $c->stash->{autodata};
  
  my $method = 'create_user';
  my $cb;
  
  my $auth_plugin = $c->auth;
  
  if(defined $groups)
  {
    $method = 'create_user_cb';
    $auth_plugin = $c->auth->_find_create_user_cb;
    return $c->render_message('not ok', 501)
      unless defined $auth_plugin;
    $cb = sub {
      foreach my $group (split /\s*,\s*/, $groups)
      {
        my $users = $c->app->authz->add_user_to_group($group, $user);
        $c->app->emit(create_group => {
          admin => $c->stash('user'),
          group => $group,
          users => $users,
        });
      }
    };
  }
  
  if($auth_plugin->$method($user, $password, $cb))
  {
    $c->render_message('ok', 200);
    $c->app->emit('user_list_changed');  # deprecated, but documented in a previous version
    $c->app->emit(create_user => {
      admin => $c->stash('user'),
      user  => $user,
    });
  }
  else
  {
    $c->render_message('not ok', 403);
  }
};


del '/user/#username' => sub {
  my $c = shift;
  my $user = $c->param('username');
  if($c->auth->delete_user($user))
  {
    $c->render_message('ok', 200);
    $c->app->emit('user_list_changed');  # deprecated, but documented in a previous version
    $c->app->emit(delete_user => {
      admin => $c->stash('user'),
      user  => $user,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


post '/group' => sub {
  my $c = shift;
  $c->parse_autodata;
  my $group = $c->stash->{autodata}->{group};
  my $users = $c->stash->{autodata}->{users};
  delete $c->stash->{autodata};
  if($c->authz->create_group($group, $users))
  {
    $c->render_message('ok',     200);
    $c->app->emit(create_group => {
      admin => $c->stash('user'),
      group => $group,
      users => $users,
    });
  }
  else
  {
    $c->render_message('not ok', 403);
  }
};


del '/group/:group' => sub {
  my $c = shift;
  my $group = $c->param('group');
  if($c->authz->delete_group($group))
  {
    $c->render_message('ok',     200);
    $c->app->emit(delete_group => {
      admin => $c->stash('user'),
      group => $group,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


post '/group/:group' => sub {
  my $c = shift;
  $c->parse_autodata;
  my $users = $c->stash->{autodata}->{users};
  my $group = $c->param('group');
  delete $c->stash->{autodata};
  if($c->authz->update_group($group, $users))
  {
    $c->render_message('ok',     200);
    $c->app->emit(update_group => {
      admin => $c->stash('user'),
      group => $group,
      users => $users,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


post '/group/:group/#username' => sub {
  my($c) = @_;
  my $group = $c->stash('group');
  my $user  = $c->stash('username');
  if(my $users = $c->authz->add_user_to_group($group, $user))
  {
    $c->render_message('ok', 200);
    $c->app->emit(update_group => {
      admin => $c->stash('user'),
      group => $group,
      users => $users,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


del '/group/:group/#username' => sub {
  my($c) = @_;
  my $group = $c->stash('group');
  my $user  = $c->stash('username');
  if(my $users = $c->authz->remove_user_from_group($group, $user))
  {
    $c->render_message('ok', 200);
    $c->app->emit(update_group => {
      admin => $c->stash('user'),
      group => $group,
      users => $users,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


post '/grant/#group/:action1/(*resource)' => { resource => '/' } => sub {
  my $c = shift;
  my($group, $action, $resource) = map { $c->stash($_) } qw( group action1 resource );
  $resource =~ s/\.(json|yml)$//;
  if($c->authz->grant($group, $action, $resource))
  {
    $c->render_message('ok',     200);
    $c->app->emit(grant => {
      admin => $c->stash('user'),
      group => $group,
      action => $action,
      resource => $resource,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


del '/grant/#group/:action1/(*resource)' => { resource => '/' } => sub {
  my($c) = @_;
  my($group, $action, $resource) = map { $c->stash($_) } qw( group action1 resource );
  $resource =~ s/\.(json|yml)$//;
  if($c->authz->revoke($group, $action, $resource))
  {
    $c->render_message('ok',     200);
    $c->app->emit(revoke => {
      admin => $c->stash('user'),
      group => $group,
      action => $action,
      resource => $resource,
    });
  }
  else
  {
    $c->render_message('not ok', 404);
  }
};


get '/grant' => sub {
  my($c) = @_;
  $c->stash->{autodata} = $c->authz->granted;
};


authenticate;
authorize 'change_password';

post '/user/#username' => sub {
  my($c) = @_;
  $c->parse_autodata;
  my $user = $c->param('username');
  my $password = eval { $c->stash->{autodata}->{password} } || '';
  delete $c->stash->{autodata};
  if($c->auth->change_password($user, $password))
  {
    $c->render_message('ok',     200);
    $c->app->emit(change_password => { admin => $c->stash('user'), user => $user });
  }
  else
  {
    $c->render_message('not ok', 403);
  }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Routes - routes for plugauth

=head1 VERSION

version 0.39

=head1 DESCRIPTION

This module defines the HTTP URL routes provided by L<PlugAuth>.
This document uses Mojolicious conventions to describe routes,
see L<Mojolicious::Guides::Routing> for details.

=head1 ROUTES

=head2 Public routes

These routes work for unauthenticated and unauthorized users.

=head3 GET /

Returns the string "welcome to plug auth"

=head3 GET /auth

=over 4

=item * if username and password provided using BASIC authentication and are correct

Return 200 ok

=item * if username and password provided using BASIC authentication but are not correct

Return 403 not ok

=item * if username and password are not provided using BASIC authentication

Return 401 please authenticate

=back

=head3 GET /authz/user/#user/#action/(*resource)

=over 4

=item * if the given user (#user) is permitted to perform the given action (#action) on the given resource (*resource)

Return 200 ok

=item * otherwise

Return 403 "unauthorized : $user cannot $action $resource"

=back

=head3 GET /authz/resources/#user/#action/(*resourceregex)

Returns a list of resources that the given user (#user) is permitted to perform
action (#action) on.  The regex is used to filter the results (*resourceregex).

=head3 GET /actions

Return a list of actions that PlugAuth knows about.

=head3 GET /groups/#user

Return a list of groups that the given user (#user) belongs to. 

Returns 404 not ok if the user does not exist.

=head3 GET /host/#host/:tag

=over 4

=item * if the given host (#host) has the given tag (:tag)

return 200 ok

=item * otherwise

return 403 not ok

=back

=head3 GET /user

Returns a list of all users that PlugAuth knows about.

=head3 GET /group

Returns a list of all groups that PlugAuth knows about.

=head3 GET /users/:group

Returns the list of users that belong to the given group (:group)

=head2 Accounts Routes

These routes are available to users authenticates and authorized to perform
the 'accounts' action.  They will return

=over 4

=item * 401

If no credentials are provided

=item * 403

If the user is unauthorized.

=item * 503

If the PlugAuth server cannot reach itself or the delegated PlugAuth server.

=back

=head3 POST /user

Create a user.  The C<username> and C<password> are provided autodata arguments
(JSON, YAML, form data, etc).

If supported by your authentication plugin (requires C<create_user_cb> to be
implemented see L<PlugAuth::Plugin::Auth> for details) You may also optionally
include C<groups> as an autodata argument, which specifies the list of groups
to which the new user should belong.  C<groups> should be a comma separated
list stored as a string.

Emits event 'create_user' on success

 $app->on(create_user => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who created the group
   my $user     = $hash->{user};
 });

=head3 DELETE /user/#user

Delete the given user (#user).  Returns 200 ok on success, 404 not ok on failure.

Emits event 'delete_user' on success

 $app->on(delete_user => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who created the group
   my $user     = $hash->{user};
 });

=head3 POST /group

Create a group.  The C<group> name and list of C<users> are provided as autodata
arguments (JSON, YAML, form data etc).  Returns 200 ok on success, 403 not ok
on failure.

Emits event 'create_group' on success

 $app->on(create_group => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who created the group
   my $group    = $hash->{group};
   my $users    = $hash->{users};
 });

=head3 DELETE /group/:group

Delete the given group (:group).  Returns 200 ok on success, 403 not ok on failure.

Emits event 'delete_group' on success

 $app->on(delete_group => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who deleted the group
   my $group    = $hash->{group};
 });

=head3 POST /group/:group

Update the list of users belonging to the given group (:group).  The list
of C<users> is provided as an autodata argument (JSON, YAML, form data etc.).
Returns 200 ok on success, 404 not ok on failure.

Emits event 'update_group' on success

 $app->on(update_group => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who updated the group
   my $group    = $hash->{group};
   my $users    = $hash->{users};
 });

=head3 POST /group/:group/#username

Add the given user (#username) to the given group (:group).
Returns 200 ok on success, 404 not ok on failure.

Emits event 'update_group' (see route for POST /group/:group for
an example).

=head3 DELETE /group/:group/#username

Remove the given user (#username) from the given group (:group).
Returns 200 ok on success, 404 not ok on failure.

Emits event 'update_group' (see route for POST /group/:group for
an example).

=head3 POST /grant/#group/:action1/(*resource)

Grant access to the given group (#group) so they can perform the given action (:action1)
on the given resource (*resource).  Returns 200 ok on success, 404 not ok on failure.

Emits event 'grant' on success

 $app->on(grant => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who did the granting
   my $group    = $hash->{group};
   my $action   = $hash->{action};
   my $resource = $hash->{resource};
 });

=head3 DELETE /grant/#group/:action1/(*resource)

Revoke permission to the given group (#group) to perform the given action (:action1) on
the given resource (*resource).  Returns 200 ok on success, 404 not ok on failure.

(the action is specified in the route as action1 because action is reserved by
L<Mojolicious>).

Emits event 'revoke' on success

 $app->on(revoke => sub {
   my($event, $hash) = @_;
   my $admin    = $hash->{admin};  # user who did the revoking
   my $group    = $hash->{group};
   my $action   = $hash->{action};
   my $resource = $hash->{resource};
 });

=head3 GET /grant

Get the list of granted permissions.

=head2 Change Password routes

These routes are available to users authenticates and authorized to perform
the 'change_password' action.  They will return

=over 4

=item * 401

If no credentials are provided

=item * 403

If the user is unauthorized.

=item * 503

If the PlugAuth server cannot reach itself or the delegated PlugAuth server.

=back

=head3 POST /user/#user

Change the password of the given user (#user).  The C<password> is provided as
an autodata argument (JSON, YAML, form data, etc.).  Returns 200 ok on success,
403 not ok on failure.

Emits event 'change_password' on success

 $app->on(change_password => sub {
   my($event, $hash) = @_;
   my $admin = $hash->{admin};  # user who changed the password
   my $user  = $hash->{user};   # user whos password is changed
 });

=head1 SEE ALSO

L<PlugAuth>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
