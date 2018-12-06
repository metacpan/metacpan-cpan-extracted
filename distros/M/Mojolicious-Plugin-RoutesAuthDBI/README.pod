package Mojolicious::Plugin::RoutesAuthDBI;
use Mojo::Base 'Mojolicious::Plugin::Authentication';
use Mojolicious::Plugin::RoutesAuthDBI::Util qw(load_class);
use Mojo::Util qw(hmac_sha1_sum);
use Hash::Merge qw( merge );
use Scalar::Util 'weaken';

use constant  PKG => __PACKAGE__;

has [qw(app dbh conf)];

has default => sub {
  my $self = shift;
  require Mojolicious::Plugin::RoutesAuthDBI::Schema;
  {
  auth => {
    stash_key => PKG."__user__",
    current_user_fn => 'auth_user',# helper
    load_user => \&load_user,
    validate_user => \&validate_user,
  },
  
  access => {
    namespace => PKG,
    module => 'Access',
    fail_auth_cb => sub {
      shift->render(status => 401, format=>'txt', text=>"Please sign in.\n");
    },
    fail_access_cb => sub {
      shift->render(status => 403, format=>'txt', text=>"You don`t have access on this route (url, action).\n");
    },
    import => [qw(load_user validate_user)],
  },
  
  admin => {
    namespace => PKG,
    controller => 'Admin',
    prefix => lc($self->conf->{admin}{controller} || 'admin'),
    trust => hmac_sha1_sum('admin', $self->app->secrets->[0]),
    role_admin => 'administrators',
  },
  
  oauth => {
    namespace => PKG,
    controller => 'OAuth',
    fail_auth_cb => sub {shift->render(format=>'txt', text=>"@_")},
  },
  
  template => $Mojolicious::Plugin::RoutesAuthDBI::Schema::defaults,
  
  model_namespace => PKG.'::Model',
  
  guest => {# from Mojolicious::Plugin::Authentication
    #~ autoload_user => 1,
    session_key => 'guest_data',
    stash_key => PKG."__guest__",
    #~ current_user_fn => 'current_guest',# helper
    #~ load_user => \&load_guest,
    #~ validate_user => not need
    #~ fail_render => not need
    #######end Mojolicious::Plugin::Authentication conf#######
    namespace => PKG,
    module => 'Guest',
    #~ import => [qw(load_guest)],
  },
  log=>{
    namespace => PKG,
    module => 'Log',
    disabled=>0,
  },
  };
};# end defaults

has merge_conf => sub {#hashref
  my $self = shift;
  merge($self->conf, $self->default);
};

has access => sub {# object
  my $self = shift;
  weaken $self;
  my $conf = $self->merge_conf->{'access'};
  @{$self->merge_conf->{template}{tables}}{keys %{$conf->{tables}}} = values %{$conf->{tables}}
    if $conf->{tables};
  my $class = load_class($conf);
  $class->import( @{ $conf->{import} });
  $class->new(app=>$self->app, plugin=>$self,);
}, weak => 1;

has admin => sub {# object
  my $self = shift;
  my $conf = $self->merge_conf->{'admin'};
  @{$self->merge_conf->{template}{tables}}{keys %{$conf->{tables}}} = values %{$conf->{tables}}
    if $conf->{tables};
  load_class($conf)->init(%$conf, app=>$self->app, plugin=>$self,);
}, weak => 1;

has oauth => sub {
  my $self = shift;
  my $conf = $self->merge_conf->{'oauth'};
  @{$self->merge_conf->{template}{tables}}{keys %{$conf->{tables}}} = values %{$conf->{tables}}
    if $conf->{tables};
  load_class($conf)->init(%$conf, app=>$self->app, plugin=>$self, model=>$self->model($conf->{controller}),);
}, weak => 1;

has guest => sub {# object
  my $self = shift;
  my $conf = $self->merge_conf->{'guest'};
  @{$self->merge_conf->{template}{tables}}{keys %{$conf->{tables}}} = values %{$conf->{tables}}
    if $conf->{tables};
  
  $self->merge_conf->{template}{tables}{guests} = $conf->{table}
    if $conf->{table};
  
  my $class = load_class($conf);
  $class->new( %$conf, app=>$self->app, plugin=>$self, model=>$self->model($conf->{module}), );
}, weak => 1;

has log => sub {# object
  my $self = shift;
  my $conf = $self->merge_conf->{'log'};
  
  @{$self->merge_conf->{template}{tables}}{keys %{$conf->{tables}}} = values %{$conf->{tables}}
    if $conf->{tables};
  
  $self->merge_conf->{template}{tables}{logs} = $conf->{table}
    if $conf->{table};
  
  my $class = load_class($conf);
  $class->new( %$conf, app=>$self->app, plugin=>$self, model=>$self->model($conf->{module}), )
    unless $conf->{disabled};
}, weak => 1;

#~ has model => sub {
  #~ my $m = { map {$_ => load_class("Mojolicious::Plugin::RoutesAuthDBI::Model::$_")->new} qw(Profiles Namespaces Routes Refs Controllers Actions Roles Logins) };
  
#~ };

sub register {
  my $self = shift;
  $self->app(shift);
  $self->conf(shift); # global
  
  $self->dbh($self->conf->{dbh} || $self->app->dbh);
  $self->dbh($self->dbh->($self->app))
    if ref($self->dbh) eq 'CODE';
  die "Plugin must work with dbh, see SYNOPSIS" unless $self->dbh;
  
  # init base model
  load_class($self->merge_conf->{model_namespace}."::Base")->singleton(dbh=>$self->dbh, template_vars=>$self->merge_conf->{template}, mt=>{tag_start=>'{%', tag_end=>'%}'});
  
  my $access = $self->access;
  
  die "Plugin [Authentication] already loaded"
    if $self->app->renderer->helpers->{'authenticate'};
  
  $self->SUPER::register($self->app, $self->merge_conf->{auth});
  $self->app->plugin('HeaderCondition');# routes host_re
  
  weaken $self;
  $self->app->routes->add_condition(access => sub {$self->cond_access(@_)});
  $access->apply_ns();
  $access->apply_route($_) for @{ $access->routes };
  
  if ($self->conf->{oauth}) {
    my $oauth = $self->oauth;
    $access->apply_route($_) for $oauth->_routes;
  }
  
  if ($self->conf->{admin}) {
    my $admin = $self->admin;
    $access->apply_route($_) for $admin->self_routes;
  }
  
  $self->guest
    if $self->conf->{guest};
  
  $self->log
    if $self->conf->{log};
  
  weaken $access;
  $self->app->helper('access', sub {$access});
  
  return $self, $access;

}

sub cond_access {# add_condition
  my $self= shift;
  my ($route, $c, $captures, $args) = @_;# $args - это маршрут-хэш из запроса БД или хэш-конфиг из кода 
  $route->{(PKG)}{route} = $args;# может пригодиться: $c->match->endpoint->{'Mojolicious::Plugin::RoutesAuthDBI'}...
  my $conf = $self->merge_conf;
  my $app = $c->app;
  my $access = $self->access;
  #~ $app->log->debug($c->dumper($route));#$route->pattern->defaults
  
  my $auth_helper = $conf->{auth}{current_user_fn};
  my $u = $c->$auth_helper;
  my $fail_auth_cb = $conf->{access}{fail_auth_cb};
  
  if (ref $args eq 'CODE') {
    $args->($u, @_)
      or $self->deny_log($route, $args, $u, $c)
      and $c->$fail_auth_cb()
      and return undef;
    $app->log->debug(sprintf(qq[Access allow [%s] by callback condition],
      $route->pattern->unparsed,
    ));
    return 0x01;
  }
  
  $app->log->debug(
    sprintf(qq[Access allow [%s] for none {auth} and none {role} and none {guest}], $route->pattern->unparsed)
  )
    and return 1 # не проверяем доступ
    unless $args->{auth} || $args->{role} || $args->{guest};
  
  
  if ($args->{guest}) {#  && $args->{auth} =~ m'\bguest\b'i
    $app->log->debug(sprintf(qq[Access allow [%s] for {guest}],
        $route->pattern->unparsed,
      ))
      and return 1
      if $self->guest->is_guest($c);
  }
  
  # не авторизовался
  $self->deny_log($route, $args, $u, $c)
    and $c->$fail_auth_cb()
    and return undef
    unless $u && $u->{id};
  
  # допустить если {auth=>'only'}
  $app->log->debug(sprintf(qq[Access allow [%s] for {auth}=~'only'],
    $route->pattern->unparsed,
  ))
    and return 1
    if $args->{auth} && $args->{auth} =~ m'\bonly\b'i;

  my $id2 = [$u->{id}, map($_->{id}, grep !$_->{disable},@{$u->roles})];
  my $id1 = [grep $_, @$args{qw(id route_id action_id controller_id namespace_id)}];
  
  # explicit acces to route
  scalar @$id1
    && $access->access_explicit($id1, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] joined id1=%s; args=[%s]; defaults=%s",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $c->dumper($id1) =~ s/\s+//gr,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
  
  # Access to non db route by role
  $args->{role}
    && $access->access_role($args->{role}, $id2)
    && $app->log->debug(sprintf "Access allow [%s] by role [%s]",
      $route->pattern->unparsed,
      $args->{role},
    )
    && return 1;
  
  # implicit access to non db routes
  my $controller = $args->{controller} || $route->pattern->defaults->{controller} && ucfirst(lc($route->pattern->defaults->{controller}));
  my $namespace = $args->{namespace} || $route->pattern->defaults->{namespace};
  if ($controller && !$namespace) {
    (load_class(namespace=>$_, controller=>$controller) and ($namespace = $_) and last) for @{ $app->routes->namespaces };
    #~ warn "FOUND CONTROLLER[$controller] in NAMESPACE: $namespace";
  }
  
  my $fail_access_cb = $conf->{access}{fail_access_cb};
  
  $self->deny_log($route, $args, $u, $c)
    and $c->$fail_access_cb()
    and return undef
    unless $controller && $namespace;# failed load class

  $access->access_namespace($namespace, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] by namespace=[%s]; args=[%s]; defaults=[%s]",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $namespace,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
  
  $access->access_controller($namespace, $controller, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] by namespace=[%s] and controller=[%s]; args=[%s]; defaults=[%s]",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $namespace, $controller,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
    
  # еще раз контроллер, который тут без namespace и в базе без namespace ------> доступ из любого места
  $args->{namespace} || $route->pattern->defaults->{namespace}
    || $access->access_controller(undef, $controller, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] by controller=[%s] without namespace on db; args=[%s]; defaults=[%s]",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $controller,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
  
  my $action = $args->{action} || $route->pattern->defaults->{action}
    or $self->deny_log($route, $args, $u, $c)
    and $c->$fail_access_cb()
    and return undef;
  
  $access->access_action($namespace, $controller, $action, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] by namespace=[%s] and controller=[%s] and action=[%s]; args=[%s]; defaults=[%s]",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $namespace , $controller, $action,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
  
  # еще раз контроллер, который тут без namespace и в базе без namespace ------> доступ из любого места
  $args->{namespace} || $route->pattern->defaults->{namespace}
    && $access->access_action(undef, $controller, $action, $id2)
    && $app->log->debug(sprintf "Access allow [%s] for roles=[%s] by (namespace=[any]) controller=[%s] and action=[%s]; args=[%s]; defaults=[%s]",
      $route->pattern->unparsed,
      $c->dumper($id2) =~ s/\s+//gr,
      $controller, $action,
      $c->dumper($args) =~ s/\s+//gr,
      $c->dumper($route->pattern->defaults) =~ s/\s+//gr,
    )
    && return 1;
    
  $self->deny_log($route, $args, $u, $c);
  $c->$fail_access_cb();
  return undef;
}

sub deny_log {
  my $self = shift;
  my ($route, $args, $u, $c) = @_;
  my $app = $self->app;
  $app->log->debug(sprintf "Access deny [%s] for profile id=[%s]; args=[%s]; defaults=[%s]",
    $route->pattern->unparsed,
    $u ? $u->{id} : 'non auth',
    $app->dumper($args) =~ s/\s+//gr,
    $app->dumper($route->pattern->defaults) =~ s/\s+//gr,
  );
}

sub model {
  my ($self, $name) = @_;
  my $ns = $self->merge_conf->{'model_namespace'};
  my $class =  load_class(namespace => $ns, module=> $name)
    or die "Model module [$name] not found at namespace [$ns] or has errors";
  
  weaken $self;
  weaken $self->{app};
  $class->new(app=>$self->app, plugin=>$self); # синглетоны в общем
  
  #~ my $m = { map {$_ => load_class("Mojolicious::Plugin::RoutesAuthDBI::Model::$_")->new} qw(Profiles Namespaces Routes Refs Controllers Actions Roles Logins) };
  
};

our $VERSION = '0.861';

=pod

=encoding utf8

=head1 Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 Mojolicious::Plugin::RoutesAuthDBI

Plugin makes an auth operations throught the plugin L<Mojolicious::Plugin::Authentication> and OAuth2 by L<Mojolicious::Plugin::OAuth2>.

=head1 VERSION

0.861

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI - from DBI tables does generate app routes, make authentication and make restrict access (authorization).

=head1 DB DESIGN DIAGRAM

First of all you will see L<SVG|https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/blob/master/Diagram.svg>  or L<PNG|http://i.imgur.com/CwqiB4f.png>

=head1 SYNOPSIS

  $app->plugin('RoutesAuthDBI',
    dbh => $app->dbh,
    auth => {...},
    access => {...},
    admin => {...},
    oauth => {...},
    guest => {...},
    template => {...},
    model_namespace=>...,
  );


=head2 PLUGIN OPTIONS

One option C<dbh> is mandatory, all other - optional.

=head3 dbh

Handler DBI connection where are tables: controllers, actions, routes, logins, profiles, roles, refs and oauth.

  dbh => $app->dbh,
  # or
  dbh => sub { shift->dbh },

=head3 auth

Hashref options pass to base plugin L<Mojolicious::Plugin::Authentication>.
By default the option:

  current_user_fn => 'auth_user',
  stash_key => "Mojolicious::Plugin::RoutesAuthDBI__user__",
    
The options:

  load_user => \&load_user,
  validate_user => \&validate_user,

are imported from package access module. See below.

=head3 access

Hashref options for special access module. This module has subs/methods for manage auth and access operations, has appling routes from DBI table. By default plugin will load the builtin module:

  access => {
    module => 'Access',
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    ...,
  },


You might define your own module by passing options:

  access => {
    module => 'Foo',
    namespace => 'Bar::Baz', 
    ...,
  },

See L<Mojolicious::Plugin::RoutesAuthDBI::Access> for detail options list.

=head3 admin

Hashref options for admin controller for actions on SQL tables routes, roles, profiles, logins. By default the builtin module:

  admin => {
    controller => 'Admin',
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    ...,
  },


You might define your own controller by passing options:

  admin => {
    controller => 'Foo',
    namespace => 'Bar::Baz', 
    ...,
  },

See L<Mojolicious::Plugin::RoutesAuthDBI::Admin> for detail options list.

=head3 oauth

Hashref options for oauth controller. By default the builtin module:

  oauth => {
    controller => 'OAuth',
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    ...,
  },


You might define your own controller by passing options:

  oauth => {
    controller => 'Foo::Bar::Baz',
    ...,
  },

See L<Mojolicious::Plugin::RoutesAuthDBI::OAuth> for detail options list.

=head3 guest

Hashref options for guest module. Defaults are:

  guest => {
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    module => 'Guest',
    session_key => 'guest_data',
    stash_key => "Mojolicious::Plugin::RoutesAuthDBI__guest__",
    
  },

Disable guest module usage:

  guest => undef, # or none in config

See L<Mojolicious::Plugin::RoutesAuthDBI::Guest>

=head3 model_namespace

Where are your models place. Default to "Mojolicious::Plugin::RoutesAuthDBI::Model".

=head3 template

Hashref variables for SQL templates of models dictionaries. Defaults is C<$Mojolicious::Plugin::RoutesAuthDBI::Schema::defaults>. See L<Mojolicious::Plugin::RoutesAuthDBI::Model::Base>.

=head1 INSTALL

See L<Mojolicious::Plugin::RoutesAuthDBI::Install>.

=head1 OVER CONDITIONS

=head2 access

Heart of this plugin! This condition apply for all db routes even if column auth set to 0. It is possible to apply this condition to non db routes also:

=over 4

=item * No access check to route, but authorization by session will ready:

  $r->route('/foo')->...->over(access=>{auth=>0})->...;

=item * Allow if has authentication only:

  $r->route('/foo')->...->over(access=>{auth=>'only'})->...;
  # same as
  # $r->route('/foo')->...->over(authenticated => 1)->...; # see Mojolicious::Plugin::Authentication

=item * Allow for guest

  $r->route('/foo')->...->over(access=>{guest=>1})->...;
  
To makes guest session:

  $c->access->plugin->guest->store($c, {<...some data...>});

See L<Mojolicious::Plugin::RoutesAuthDBI::Guest>

=item * Route accessible if profile roles assigned to either B<loadable> namespace or controller 'Bar.pm' (which assigned neither namespece on db or assigned to that loadable namespace) or action 'bar' on controller Bar.pm (action record in db table actions):

  $r->route('/bar-bar-any-namespace')->to('bar#bar',)->over(access=>{auth=>1})->...;

=item * Explicit defined namespace route accessible either namespace 'Bar' or 'Bar::Bar.pm' controller or action 'bar' in controller 'Bar::Bar.pm' (which assigned to namespace 'Bar' in table refs):

  $r->route('/bar-bar-bar')->to('bar#bar', namespace=>'Bar')->over(access=>{auth=>1})->...;

=item * Check access by overriden namespace 'BarX': controller and action also with that namespace in db table refs:

  $r->route('/bar-nsX')->to('bar#bar', namespace=>'Bar')->over(access=>{auth=>1, namespace=>'BarX'})->...;

=item * Check access by overriden namespace 'BarX' and controller 'BarX.pm', action record also with that ns & c in db table refs:

  $r->route('/bar-nsX-cX')->to('bar#bar', namespace=>'Bar')->over(access=>{auth=>1, namespace=>'BarX', controller=>'BarX'})->...;

=item * Full override names access:

  $r->route('/bar-nsX-cX-aX')->to('bar#bar', namespace=>'Bar')->over(access=>{auth=>1, namespace=>'BarX', controller=>'BarX', action=>'barX'})->...;

=item *

  $r->route('/bar-cX-aX')->to('bar#bar',)->over(access=>{auth=>1, controller=>'BarX', action=>'barX'})->...;

=item * Route accessible if profile roles list has defined role (admin):

  $r->route('/bar-role-admin')->to('bar#bar',)->over(access=>{auth=>1, role=> 'admin'})->...;
  
=item * Pass callback to access condition

The callback will get parameters: $profile, $route, $c, $captures, $args (this callback ref). Callback must returns true or false for restrict access. Example simple auth access:

  $r->route('/check-auth')->over(access=>sub {my ($profile, $route, $c, $captures, $args) = @_; return $profile;})->to(cb=>sub {my $c =shift; $c->render(format=>'txt', text=>"Hi @{[$c->auth_user->{names}]}!\n\nYou have access!");});

=back

=head1 HELPERS

=head2 access

Returns access instance obiect. See L<Mojolicious::Plugin::RoutesAuthDBI::Access> methods.

  if ($c->access->access_explicit([1,2,3], [1,2,3])) {
    # yes, accessible
  }

=head1 METHODS and SUBS

Registration() & access() & <internal>.

=head2 Example routing table records

    Request
    HTTP method(s) (optional)
    and the URL (space delim)
                               Contoller    Method          Route Name        Auth
    -------------------------  -----------  --------------  ----------------- -----
    GET /city/new              City         new_form        city_new_form     1
    GET /city/:id              City         show            city_show         1
    GET /city/edit/:id         City         edit_form       city_edit_form    1
    GET /cities                City         index           city_index        1
    POST /city                 City         save            city_save         1
    GET /city/delete/:id       City         delete_form     city_delete_form  1
    DELETE /city/:id           City         delete          city_delete       1
    /                          Home         index           home_index        0
    get post /foo/baz          Foo          baz             foo_baz           1

It table will generate the L<Mojolicious routes|http://mojolicious.org/perldoc/Mojolicious/Guides/Routing>:

    # GET /city/new 
    $r->route('/city/new')->via('get')->over(<access>)->to(controller => 'city', action => 'new_form')->name('city_new_form');

    # GET /city/123 - show item with id 123
    $r->route('/city/:id')->via('get')->over(<access>)->to(controller => 'city', action => 'show')->name('city_show');

    # GET /city/edit/123 - form to edit an item
    $r->route('/city/edit/:id')->via('get')->over(<access>)->to(controller => 'city', action => 'edit_form')->name('city_edit_form');

    # GET /cities - list of all items
    $r->route('/cities')->via('get')->over(<access>)->to(controller => 'city', action => 'index')->name('cities_index');

    # POST /city - create new item or update the item
    $r->route('/city')->via('post')->to(controller => 'city', action => 'save')->name('city_save');
    
    # GET /city/delete/123 - form to confirm delete an item id=123
    $r->route('/city/delete/:id')->via('get')->over(<access>)->to(controller => 'city', action => 'delete_form')->name('city_delete_form');

    # DELETE /city/123 - delete an item id=123
    $r->route('/city/:id')->via('delete')->over(<access>)->to(controller => 'city', action => 'delete')->name('city_delete');
        
    # without HTTP method and no auth restrict
    $r->route('/')->to(controller => 'Home', action => 'index')->name('home_index');
        
    # GET or POST /foo/baz 
    $r->route('/foo/baz')->via('GET', 'post')->over(<access>)->to(controller => 'Foo', action => 'baz')->name('foo_baz');

=head2 Warning

If you changed the routes table then kill -HUP or reload app to regenerate routes. Changing assess not require reloading the service.

=head1 SEE ALSO

L<Mojolicious::Plugin::Authentication>

L<Mojolicious::Plugin::Authorization>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

