package Mojolicious::Plugin::RoutesAuthDBI::Access;
use Mojo::Base -base;
use Exporter 'import'; 
our @EXPORT_OK = qw(load_user validate_user);
use Mojolicious::Plugin::RoutesAuthDBI::Util qw(load_class);
use Mojo::Util qw(md5_sum);
#~ use Mojo::Exception;

has [qw(app plugin)], undef, weak=>1;
has qw(model);

#~ has model_profiles => sub { shift->plugin->model('Profiles') };
#~ has model => sub {
  #~ { map $_ => load_class("Mojolicious::Plugin::RoutesAuthDBI::Model::$_")->new, qw(Profiles Namespaces Routes Refs Controllers Actions Roles) }
#~ };

sub new {# from plugin! init Class vars
  state $self = shift->SUPER::new(@_);
}

sub load_user {# import for Mojolicious::Plugin::Authentication
  my ($c, $uid) = @_;
  
  my $p = load_class("Mojolicious::Plugin::RoutesAuthDBI::Model::Profiles")->get_profile($uid, undef);
  #~ my $p = $c->model_profiles->get_profile($uid, undef);
  
  $c->app->log->debug("Loading profile by id=$uid failed")
    and return undef
    unless $p && $p->{id};
    
  #~ eval { Mojo::Exception->throw('load_user') };
  #~ $c->app->log->debug($c->dumper($_)) for @{$@->frames};
  
  $c->app->log->debug("Loading profile by id=$uid success");
  $p->{pass} = '**********************';
  return $p;
}

sub validate_user {# import for Mojolicious::Plugin::Authentication
  my ($c, $login, $pass, $extradata) = @_;
  
  return $extradata->{id}
    if $extradata && $extradata->{id};
  
  if (my $p = load_class("Mojolicious::Plugin::RoutesAuthDBI::Model::Profiles")->get_profile(undef, $login)) {
  #~ if (my $p = $c->model_profiles->get_profile(undef, $login)) {
    $c->app->log->debug("Success authenticate by login[$login]/pass[$pass] for profile id[$p->{id}]")
      and return $p->{id}
      if ($p->{pass} eq $pass || $p->{pass} eq md5_sum($pass))
        && !$p->{disable};
    
    $c->app->log->debug("Failure authenticate by login[$login]/pass[$pass]:[@{[md5_sum($pass)]}] for profile id[$p->{id}:$p->{pass}]");
    
    return undef;
  }
  
  $c->app->log->debug("Failure authenticate by login[$login]/pass[$pass]:[@{[md5_sum($pass)]}]");
  
  return undef;
}

sub apply_ns {# Plugin
  my ($self,) = @_;
  my $ns = $self->plugin->model('Namespaces')->app_ns;
  return unless @$ns;
  my $r = $self->app->routes;
  push @{ $r->namespaces() }, $_->{namespace} for @$ns;
}

sub apply_route {# meth in Plugin
  my ($self, $r_hash) = @_;# $r_hash - это строка запроса маршрута из БД
  my $r = $self->app->routes;
  
  $self->app->log->debug("Skip disabled route id=[$r_hash->{id}] [$r_hash->{request}]")
    and return undef
    if $r_hash->{disable};
  
  $r_hash->{request} //= $r_hash->{route};
  
  $self->app->log->debug("Skip route @{[$self->app->dumper($r_hash) =~ s/\s+//gr]}: empty request")
    and return undef
    unless $r_hash->{request};
  
  $self->app->log->debug("Skip comment request [$r_hash->{request}]")
    and return undef
    if $r_hash->{request} =~ /^#/;
  
  my @request = grep /\S/, split /\s+/, $r_hash->{request}
    or $self->app->log->debug("Skip route @{[$self->app->dumper($r_hash) =~ s/\s+//gr]}: bad request")
    and return;
  
  my $nr;
  if (@request eq 2 && $request[0] =~ /websocket|ws/i) {
    $nr = $r->websocket(pop @request);
  } else {
    $nr = $r->any(pop @request);#Mojolicious::Routes::Route::route is DEPRECATED
    $nr->methods(@request)# Deprecated Mojolicious::Routes::Route::via in favor of Mojolicious::Routes::Route::methods.
      if @request;
  }
  # STEP AUTH не катит! только один over!
  #~ $nr->over(authenticated=>$r_hash->{auth});
  # STEP ACCESS
  $nr->requires(access => $r_hash);# Deprecated Mojolicious::Routes::Route::over in favor of Mojolicious::Routes::Route::requires
  my $host = eval($r_hash->{host_re} || $r_hash->{host} || '');
  $nr->requires(host => $host)
    if $host;
  
# Controller and action in Mojolicious::Routes::Route->to
    #~ elsif ($shortcut =~ /^([\w\-:]+)?\#(\w+)?$/) {
      #~ $defaults{controller} = $1 if defined $1;
      #~ $defaults{action}     = $2 if defined $2;
    #~ }
    
  my @to = ($r_hash->{namespace} ? ("namespace" => $r_hash->{namespace}) : (), 
    $r_hash->{controller} ? ("controller"=>$r_hash->{controller},) : ());

  if ($r_hash->{to}) {
    $nr->to($r_hash->{to}, @to); 
  } elsif ( $r_hash->{action} ) {
    
    if ( $r_hash->{action} =~ /#/ ) { $nr->to($r_hash->{action}, @to); }
    else { $nr->to( action => $r_hash->{action}, @to,); }
    
  } elsif ( $r_hash->{callback} ) {
    
    my $cb = eval $r_hash->{callback};
    die "Compile error on callback: [$@]", $self->app->dumper($r_hash)
      if $@;
    $nr->to(cb => $cb);
    
  } else {
    die "No defaults for route: ", $self->app->dumper($r_hash);
  }
  $nr->name($r_hash->{name})
    if $r_hash->{name};
  $self->app->log->debug("Apply DBI route [$r_hash->{request}] ". $self->app->dumper($nr->pattern->defaults) =~ s/\s*
  \n+\s*//gr);
  return $nr;
}

sub routes {
  my ($self,) = @_;
  $self->plugin->model('Routes')->routes;
}

sub access_explicit {# i.e. by refs table
  my ($self, $id1, $id2,) = @_;
  my $r = $self->plugin->model('Refs')->exists($id1, $id2);
  #~ $self->app->log->debug("Test access_explicit: ", $r);
  return $r;
}


sub access_namespace {#implicit
  my ($self, $namespace, $id2,) = @_;
  return scalar $self->plugin->model('Namespaces')->access($namespace, $id2);
}

sub access_controller {#implicit
  my ($self, $namespace, $controller, $id2,) = @_;
  my $c = $self->plugin->model('Controllers')->controller_ns( $controller, ($namespace) x 2,)
    or return undef;
  $self->access_explicit([$c->{id}], $id2);
}

sub access_action {#implicit
  my ($self, $namespace, $controller, $action, $id2,) = @_;
  my $c = $self->plugin->model('Controllers')->controller_ns( $controller, ($namespace) x 2,)
    or return undef;
  return scalar $self->plugin->model('Actions')->access( $c->{id}, $action, $id2);
}

sub access_role {#implicit
  my ($self, $role, $id2,) = @_;
  return scalar $self->plugin->model('Roles')->access($role =~ /\D/ ? (undef, $role) : ($role, undef), $id2);
}

my $Mojo_Util_loaded;
sub auth_cookie {
  my ($self, $c, $value, $name) = @_;
  $name ||= $c->app->sessions->cookie_name;
  return $c->cookie($name)#'mojolicious'
    unless $value;
  
  if ($value =~ s/--([^\-]+)$//) {
    my $signature = $1;
    load_class 'Mojo::Util'
      unless $Mojo_Util_loaded++;

    my $valid;
    my $secrets = $c->app->secrets;
    for my $secret (@$secrets) {
      my $check = Mojo::Util::hmac_sha1_sum($value, $secret);
      ++$valid
        and last
        if Mojo::Util::secure_compare($signature, $check);
    }
    
    $c->app->log->warn(qq{Cookie [$value] has a bad signature})
      and return undef
      unless $valid;
    
  } else {
    $c->app->log->warn(qq{Cookie [$value] is not signed})
      and return undef;
  }

  my $session = $c->app->sessions->deserialize->(Mojo::Util::b64_decode $value)
    or $c->app->log->warn(qq{Cookie [$value] couldnt deserialize})
    and return undef;
  
  my $key =  $self->plugin->merge_conf->{auth}{session_key} || 'auth_data';
  my $profile_id = $session->{$key}
    or $c->app->log->warn(qq{Cookie [$value] doesnt has profile id})
    and return undef;
  #~ $c->app->log->fatal($c->dumper($c->stash->{'mojo.session'}), $c->stash->{'mojo.active_session'});
  #~ warn $c->auth_user || 'none auth';
  $c->authenticate(undef, undef, {id=> $profile_id}); # session only store
  #~ $c->app->sessions->store($c);
  #~ $c->app->log->fatal($c->dumper($c->stash->{'mojo.session'}), $c->stash->{'mojo.active_session'});
  #~ $c->app->log->fatal($_->name, $_->{value}) for @{$c->res->cookies};
  #~ $c->app->log->fatal( $c->dumper($c->res->cookies) );
  #~ $c->app->log->fatal( $c->dumper($c->res->headers) );
  #~ $c->res->headers->set_cookie('foo=bar; path=/');
  
  my $old_set_cookie = $c->res->headers->set_cookie;# && scalar @{$c->res->headers->{'set-cookie'}};
  #~ $c->app->log->fatal( $c->dumper($old_set_cookie) );
  #~ $c->app->log->fatal($c->cookie('mojolicious'));
  $c->app->sessions->store($c);
  #~ $c->app->log->fatal( $c->dumper( $c->res->headers->to_hash) );
  #~ my $cc = scalar @{$c->res->cookies};
  #~ $c->app->log->fatal($c->cookie('mojolicious'));
  #~ $c->app->log->fatal($_->name, $_->value) for @{$c->res->cookies});
  #~ my $new_cookie = (grep($_->name eq $name, @{$c->res->cookies}))[0];
  my $new_cookie = pop @{$c->res->cookies};
  #~ $c->app->log->fatal( $c->dumper($c->res->cookies) );
  $c->res->headers->set_cookie($old_set_cookie // 'auth=ok; path=/');
  #~ $set_cookie ? pop @{$c->res->headers->{'set-cookie'}} : delete $c->res->headers->{'set-cookie'};
  #~ $c->app->log->fatal( $c->dumper($c->res->headers) );
  #~ $c->app->log->fatal($c->dumper($c->stash->{'mojo.session'}), $c->stash->{'mojo.active_session'});
  
  my $profile = $c->auth_user;
  $profile->auth_cookie($new_cookie->value)
    #~ and unshift(@a,$x,$y)   splice(@{$c->res->cookies},0,0,$x,$y)
    if $new_cookie;
  
  return $profile;
}

1;

=pod

=encoding utf8

=head1 Mojolicious::Plugin::RoutesAuthDBI::Access

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::Access - Generation routes, authentication and controll access to routes trought sintax of ->requires(...), see L<Mojolicious::Routes::Route#requires>

=head1 DB DESIGN DIAGRAM

See L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/blob/master/Diagram.svg>

=head1 Generate the routes from DB

=over 4

=item * B<route> -> B<actions.action> <- B<controllers> [ <- B<namespaces>]

Route to action method on controller. If no ref from namespace to controller then controller will find on $app->routes->namespaces as usual.

=item * B<routes> -> B<actions.callback>

Route to callback (no ref to controller, defined I<callback> column (as text "sub {...}") in db table B<actions>)

=back

=head2 Access controll flow

There are two ways of flow: explicit and implicit.

=over 4

=item * Explicit access

Check by tables ids: routes, actions, controllers, namespaces. Check refs to profile roles ids.

=item * Implicit access

Access to routes by names: action, controller, namespace, role. This way used for db route to access namespace and for non db routes by syntax:

  $r->any('/foo')->...->to('foo#bar')->requires(access=>{auth=>1})->...; 

or

  $r->...->requires(access=>{auth=>1, role => <id|name>})->...; # access to route by role id|name

=back

See detail L<Mojolicious::Plugin::RoutesAuthDBI#access>

=head1 SYNOPSIS

    $app->plugin('RoutesAuthDBI', 
        ...
        access => {< hashref options list below >},
        ...
    );

=head1 OPTIONS for plugin

=head2 namespace

Default 'Mojolicious::Plugin::RoutesAuthDBI'.

=head2 module

Default 'Access' (this module).

Both above options determining the module which will play as manager of authentication, accessing and generate routing from DBI source.

=head2 fail_auth_cb

  fail_auth_cb => sub {my $c = shift;...}

This callback invoke when request need auth route but authentication was failure.

=head2 fail_access_cb

  fail_access_cb => sub {my ($c, $route, $r_hash, $u) = @_;...}

This callback invoke when request need auth route but access was failure. $route - L<Mojolicious::Routes::Route> object, $r_hash - route hashref db item, $u - useer hashref.

=head2 tables

Hashref of any DB tables names. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.


=head1 EXPORT SUBS

=head2 load_user($c, $uid)

Fetch user record from table profiles by COOKIES. Import for Mojolicious::Plugin::Authentication. Required.

=head2 validate_user($c, $login, $pass, $extradata)

Fetch login record from table logins by Mojolicious::Plugin::Authentication. Required. If hashref $extradata->{id} then no fetch and $extradata->{id} will return.

=head1 METHODS

As child of L<Mojolicious::Controller> inherits all parent methods and following ones:

=head2 new(app=> ..., plugin => ...)

Return new access object.

=head2 apply_ns()

Select from db table I<namespaces> ns thus app_ns=1 and push them to $app->namespaces()

=head2 apply_route($r_hash)

Heart of routes generation from db tables and not only. Insert to app->routes an hash item $r_hash. DB schema specific. Return new Mojolicious route.

=head2 routes()

Fetch records for apply_routes. Must return arrayref of hashrefs routes.

=head2 access_explicit($id1, $id2)

Check access to route ($id1 arrayref - either route id or action id or controller id or namespace id) by roles ids ($id2 arrayref). Must return false for deny access or true - allow access.

=head2 access_namespace($namespace, $id2)

Check implicit access to route by $namespace for profile roles ids ($id2 arrayref). Must return false for deny access or true - allow access to all actions of this namespace.

=head2 access_controller($namespace, $controller, $id2)

Check implicit access to route by $namespace and $controller for profile roles ids ($id2 arrayref). Must return false for deny access or true - allow access to all actions of this controller.

=head2 access_action($namespace, $controller, $action, $id2)

Check implicit access to route by $namespace and $controller and $action for profile roles ids ($id2 arrayref). Must return false for deny access or true - allow access to this action.

=head2 access_role($role, $id2)

Check implicit access to route by $role (id|name) and profile roles ids ($id2 arrayref). Must return false for deny access or true - allow access.

=head2 auth_cookie($c, $cookie_value, $cookie_name)

Returns C<< $c->cookie($cookie_name) >> unless $cookie_value.

Returns authenticate profile for $cookie_value. I use this method for cordova mobile app then cookie lost on any reasons.

C<< $cookie_name >> has defaults to C<< $c->app->sessions->cookie_name >>

=head1 SEE ALSO

L<Mojolicious::Plugin::RoutesAuthDBI>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests welcome also.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
