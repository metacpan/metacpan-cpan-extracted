package Mojolicious::Che;
use Mojo::Base::Che;
use Mojo::Base  'Mojolicious';
use Mojo::Log::Che;
use Mojo::Loader qw(load_class);
#~ use Mojo::Util qw(url_unescape);
#~ use Scalar::Util 'weaken';

sub new {
  my ($class, %args) = @_;
  my $config = delete($args{config}) || 'Config.pm';
  my $app = $class->SUPER::new(%args);
  
  $app->plugin(Config =>{file => $config});
  
  #~ return $app # остановка или двойной перезапуск kill -USR2
    #~ if $ENV{HYPNOTOAD_PID} || $ENV{HYPNOTOAD_STOP};
  
  my $conf = $app->config;
  $conf->{mojo} ||= {};
  
  my $defaults = $conf->{'mojo_defaults'} || $conf->{'mojo'}{'defaults'}  || $conf->{'mojo.defaults'};
  $app->defaults($defaults)
    if $defaults;
  
  my $secret = $conf->{'mojo_secret'} || $conf->{'mojo_secrets'} || $conf->{'mojo'}{'secret'} || $conf->{'mojo'}{'secrets'} || $conf->{'mojo.secret'} || $conf->{'mojo.secrets'} || $conf->{'шифры'} || [rand];
  $app->secrets($secret);
  
  my $mode = $conf->{'mojo_mode'} || $conf->{'mojo'}{'mode'} || $conf->{'mojo.mode'};
  $app->mode($mode) # Файл лога уже не переключишь
    if $mode;
  #~ $app->log->level( $conf->{'mojo_log_level'} || $conf->{'mojo'}{'log_level'} || 'debug');
  my $log = $conf->{'mojo_log'} || $conf->{'mojo.log'} || $conf->{'mojo'}{'log'};
  $app->log(Mojo::Log::Che->new(%$log))
    if $log;
  #~ warn "Mode: ", $app->mode, "; log level: ", $app->log->level;
  
  my $home = $app->home;
  my $statics = $conf->{'mojo_static_paths'} || $conf->{'mojo.static.paths'} || $conf->{'mojo'}{'static'}{'paths'} || [];
   #~ push @{$app->static->paths}, @{$paths} if $paths;
  push @{$app->static->paths},  $home->rel_file($_)
    for @$statics;
  
  my $templates_paths = $conf->{'mojo_renderer_paths'} || $conf->{'mojo.renderer.paths'} || $conf->{'mojo'}{'renderer'}{'paths'} || [];
  push @{$app->renderer->paths}, $home->rel_dir($_)
    for @$templates_paths;
  
  my $renderer_classes = $conf->{'mojo_renderer_classes'} || $conf->{'mojo.renderer.classes'} || $conf->{'mojo'}{'renderer'}{'classes'} || [];
  push @{$app->renderer->classes}, $_
    for grep ! load_class($_), @$renderer_classes;
  
  $app->сессия();
  $app->хазы();
  $app->плугины();
  $app->хуки();
  $app->спейсы();
  $app->маршруты();
  $app->задачи();
  $app->типы();
  #~ $app->minion_worker();

  return $app;

}

sub хазы { # Хазы из конфига
  my $app = shift;
  my $conf = $app->config;
  my $h = $conf->{'mojo_has'} || $conf->{'mojo.has'} || $conf->{'mojo'}{'has'} || $conf->{'хазы'};
  map {
    $app->log->debug("Make the app->has('$_')");
    has $_ => $h->{$_};
  } keys %$h;
}

#~ sub плугины {# Плугины из конфига
has плугины => sub {
  my $app = shift;
  my $conf = $app->config;
  my $плугины = {};
  my $plugins = $conf->{'mojo_plugins'} || $conf->{'mojo.plugins'} || $conf->{'mojo'}{'plugins'} || $conf->{'плугины'}
    || return;
  map {
    push @{ $плугины->{$_->[0]} ||= [] }, [ref $_->[1] eq 'CODE' ? $app->plugin($_->[0] => $app->${ \$_->[1] }) : $app->plugin(@$_)];
    $app->log->debug("Enable plugin [$_->[0]]");
  } @$plugins;
  return $плугины;
};

  
sub хуки {# Хуки из конфига
  my $app = shift;
  my $conf = $app->config;
  my $hooks = $conf->{'mojo_hooks'} || $conf->{'mojo.hooks'} || $conf->{'mojo'}{'hooks'} || $conf->{'хуки'}
     || return;
  while (my ($name, $sub) = each %$hooks) {
    if (ref $sub eq 'ARRAY') {
      $app->hook($name => $_)
        for @$sub;
    } else {
      $app->hook($name => $sub);
    }
    
    $app->log->debug(sprintf("Applied hook%s [%s] from config", ref $sub eq 'ARRAY' ? "s (@{[ scalar @$sub]})" : '', $name));
  }

}

sub сессия {
  my $app = shift;
  my $conf = $app->config;
  my $session = $conf->{'mojo_session'} || $conf->{'mojo_sessions'}  || $conf->{'mojo.session'}  || $conf->{'mojo.sessions'} || $conf->{'mojo'}{'session'} || $conf->{'mojo'}{'sessions'} || $conf->{'сессии'} || $conf->{'сессия'}
    || return;
  
  #~ $app->sessions->cookie_name($session->{'cookie_name'})
    #~ if $session->{'cookie_name'};
  
  #~ $app->sessions->default_expiration($session->{'default_expiration'}) # set expiry
    #~ if defined $session->{'default_expiration'};
  
  while (my ($meth, $val) = each %$session) {
    next
      unless $app->sessions->can($meth);
    $app->sessions->$meth($val);
  }
}

sub маршруты {
  my $app = shift;
  my $conf = $app->config;
  my $routes = $conf->{'mojo_routes'} || $conf->{'mojo.routes'} || $conf->{'mojo'}{'routes'} || $conf->{'routes'} || $conf->{'маршруты'}
    or return;
  my $app_routes = $app->routes;
  my $apply_route = sub {
    my $r = shift || $app_routes;
    my ($meth, $arg) = @_;
    my $nr;
    if (my $m = $r->can($meth)) {
      $nr = $r->$m($arg) unless ref($arg);
      $nr = $r->$m(cb => $arg) if ref($arg) eq 'CODE';
      $nr = $r->$m(@$arg) if ref($arg) eq 'ARRAY';
      $nr = $r->$m(%$arg) if ref($arg) eq 'HASH';
      
    }  else {
      $app->log->warn("Can't method [$meth] for route",);
    }
    return $nr;
  };
  
  for my $r (@$routes) {
    my $nr = $apply_route->($app_routes, @$r[0,1])
      or next;
    $app->log->debug("Apply route [$r->[0] $r->[1]]");
    for( my $i = 2; $i < @$r; $i += 2 ) {
      $nr = $apply_route->($nr, @$r[$i, $i+1])
        or next;
    }
  }
}

sub спейсы {
  my $app = shift;
  my $conf = $app->config;
  my $ns =  $conf->{'mojo_namespaces'} || $conf->{'mojo.namespaces'} || $conf->{'mojo'}{'namespaces'} || $conf->{'namespaces'} || $conf->{'ns'} || $conf->{'спейсы'}
    || return;
  push @{$app->routes->namespaces}, @$ns;
}

sub задачи {
  my $app = shift;
  my $conf = $app->config;
  my $tasks = $conf->{'jobs'} || $conf->{'tasks'} || $conf->{'задачи'}
    or return;
  
  die "You have jobs and first enable plugin Minion"
    unless $app->renderer->get_helper('minion');
  
  while (my ($name, $sub) = each %$tasks) {
    $app->log->debug(sprintf("Applied task [%s] in [%s] from config", $name, $app->minion->add_task($name => $sub)));
  }
  #~ $app->minion->reset;
}


sub типы {#MIME
  my $app = shift;
  my $conf = $app->config;
  my $types = $conf->{'mojo_types'}  || $conf->{'mojo.types'} || $conf->{'mojo'}{'types'} || $conf->{'types'} || $conf->{'типы'}
    or return;
  while (my ($name, $val) = each %$types) {
    $app->types->type($name => $val);
    $app->log->debug(sprintf("Applied type [%s] from config", $name));
  }
}

# overide only on my $path   = $req->url->path->to_abs_string;
sub Mojolicious::dispatch {
  my ($self, $c) = @_;

  my $plugins = $self->plugins->emit_hook(before_dispatch => $c);

  # Try to find a static file
  my $tx = $c->tx;
  $self->static->dispatch($c) and $plugins->emit_hook(after_static => $c)
    unless $tx->res->code;

  # Start timer (ignore static files)
  my $stash = $c->stash;
  $c->helpers->log->debug(sub {
    my $req    = $c->req;
    my $url = $req->url->to_abs;
    $c->helpers->timing->begin('mojo.timer');
    #~ return sprintf qq{[%s] %s "%s://%s%s%s"},
      #~ $req->request_id, $req->method, $url->scheme, $url->host, $url->port ? ":".$url->port : '', $url->path->to_route;
    return sprintf qq{%s "%s"}, $req->method, Mojo::Util::decode('UTF-8',  Mojo::Util::url_unescape($url));
  }) unless $stash->{'mojo.static'};

  # Routes
  $plugins->emit_hook(before_routes => $c);
  $c->helpers->reply->not_found
    unless $tx->res->code || $self->routes->dispatch($c) || $tx->res->code || $stash->{'mojo.rendered'};
}


our $VERSION = '0.09191';# as to Mojolicious/100+0.000<minor>

=pod

=encoding utf8

=head1 Mojolicious::Che

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 VERSION

0.09191

=head1 NAME

Mojolicious::Che - Мой базовый модуль для приложений Mojolicious. Нужен только развернутый конфиг.

=head1 SYNOPSIS

  # app.pl
  use lib 'lib';
  use Mojo::Base 'Mojolicious::Che';
  __PACKAGE__->new(config => 'lib/Config.pm')->start();


=head1 Config file

Порядок строк в этом конфиге соответствует исполнению в модуле!

  {
  'Проект'=>'Тест-проект',
  # mojo => {
    # defaults =>
    # secrets =>
    # mode=>
    # log => {level=>...}
    # static => {paths => [...]},
    # renderer => {paths => [...], classes => [...], },
    # session[s] =>
    # has =>
    # plugins =>
    # hooks =>
    # namespaces =>
    # routes =>
    # jobs =>
    # types =>
  # },
  # or with prefix mojo_
  # Default values for "stash" in Mojolicious::Controller, assigned for every new request.
  mojo_defaults => {layout=>'default',},
  # 'шифры' => [
  mojo_secrets => ['true 123 my app',],
  mojo_mode=> 'development',
  mojo_log=>{level => 'error'},
  mojo_static_paths => ["static"],
  mojo_renderer_classes => ["Mojolicious::Foo::Fun"],
  # 'сессия'(или сессии) => 
  mojo_session[s] => {cookie_name => 'EXX', default_expiration => 86400},
  
  # 'хазы' => 'Лет 500-700 назад был такой дикий степной торговый жадный народ ХАЗАРЫ. Столицей их "государства" был город Тьмутаракань, где-то на берегу моря Каспия. Потомки этих людей рассыпаны по странам России, Средней Азии, Европы. Есть мнение, что хазары присвоили себе название ЕВРЕИ, но это не те библейские кроткие евреи, а жадные потомки кроманьонцев'
  mojo_has => {
    foo => sub {my $app = shift; return 'is a bar';},
  },
  
  # 'плугины'=> [
  mojo_plugins=>[ 
      ['Foo::Bar'],
      [Foo::Bar::Plugin => opt1 => ..., opt2 => ...],
      ['Foo::Plugin' => sub {<...returns config data list...>}],
  ],
  # 'хуки' => 
  mojo_hooks=>{
    #~ before_dispatch => sub {1;},
  },
  # 'спейсы' => [...]
  namespaces => ['Space::Shattle'],
  # 'маршруты' => [...]
  routes => [
    [get=>'/', to=> {cb=>sub{shift->render(format=>'txt', text=>'Hello friend!');},}],
  ]
  #~ 'задачи'=> {#first enable plugin Minion
  jobs => {
    slow_log => sub {
      my ($job, $msg) = @_;
      sleep 5;
      $job->app->log->error(qq{slow_log "$msg"});
    },
  },
  # или 'типы'=>{...}
  types => {
    docx => ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    ...
  },
  };

=head1 ATTRIBUTES

B<Mojolicious::Che> inherits all attributes from L<Mojolicious> and implements the
following new ones.

=head2 плугины

Apply the plugins. See L<Mojolicious#plugins>, L<Mojolicious::Plugins>.

=head1 METHODS

B<Mojolicious::Che> inherits all methods from L<Mojolicious> and implements the following new ones.

=head2 сессия()

Session object config apply. See L<Mojolicious#sessions>, L<Mojolicious::Sessions>.

=head2 хазы()

Apply the has's. UTF names allow.

=head2 хуки()

Apply the hooks. See L<Mojolicious#HOOKS>.

=head2 спейсы()

Apply the namespaces. Push @{$app->routes->namespaces} your namespaces. See L<Mojolicious#routes>.

  namespaces => ['Space::Shattle'],

=head2 маршруты()

Apply the routes. See L<Mojolicious#routes>, L<Mojolicious::Guides::Routing>.

  #~ 'маршруты' => [
  'routes'=>[
    [get=>'/', to=> {cb=>sub{shift->render(format=>'txt', text=>'Welcome!');},}],
  ],

=head2 задачи()

Apply the jobs. See L<Minion>.

  #~ 'задачи'=> {#first enable plugin Minion
  'jobs'=> { # or tasks
    slow_log => sub {
      my ($job, $msg) = @_;
      sleep 5;
      $job->app->log->error(qq{slow_log "$msg"});
    },
    
  },

=head типы()

Apply the new types. See L<Mojolicious#types>, L<Mojolicious::Types>.

=head1 SEE ALSO

L<Mojolicious>

L<Ado>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Che/issues>.
Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;