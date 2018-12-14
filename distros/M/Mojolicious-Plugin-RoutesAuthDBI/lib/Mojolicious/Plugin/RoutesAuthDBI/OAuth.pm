package Mojolicious::Plugin::RoutesAuthDBI::OAuth;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Plugin::RoutesAuthDBI::Util qw(json_enc json_dec);#load_class
use Hash::Merge qw( merge );
use Digest::MD5 qw(md5_hex);

my ($Init);
has [qw(app plugin )], undef, weak=>1;
has [qw(controller namespace model)]

# state here for init and many news
#~ has model => sub { shift->_model};
#~ sub _model { state $model = load_class('Mojolicious::Plugin::RoutesAuthDBI::Model::OAuth')->new }

has _providers => sub {# default
  {
    vkontakte => {
      authorize_url => "https://oauth.vk.com/authorize",
      authorize_query => {display=>'page', response_type=>'code', v=>'5.52',},#&scope=friends
      token_url     => "https://oauth.vk.com/access_token",
      profile_url => 'https://api.vk.com/method/users.get',#?user_ids=260362925&v=5.52&access_token=...
      profile_query => sub {
        my ($c, $auth, ) = @_;
        {
          access_token=>$auth->{access_token},
          fields=>'photo_100',
        };
      },
      profile_avatar =>'photo_100',
    },
    google=>{# обязательно redirect_url
      scope=>'profile',
      profile_url=> 'https://www.googleapis.com/oauth2/v1/userinfo',
      profile_query => sub {
        my ($c, $auth, ) = @_;
        {
          alt => 'json',
          access_token => $auth->{access_token},
        };
      },
      profile_avatar =>'picture',
    },
    yandex=>{# обязательно redirect_url
      authorize_url=>"https://oauth.yandex.ru/authorize",
      authorize_query => {force_confirm=>1, response_type=>'code',},# state=>
      token_url => "https://oauth.yandex.ru/token",
      profile_url=> "https://login.yandex.ru/info",
      profile_query => sub {
        my ($c, $auth, ) = @_;
        {
          format => 'json',
          oauth_token=> $auth->{access_token},
        };
      },
      # "default_avatar_id": "458/1266-1543797358",
      profile_avatar =>'default_avatar_id',# appRoutes!!
    },
    mailru => {
      authorize_url=>"https://connect.mail.ru/oauth/authorize?response_type=code",
      token_url => "https://connect.mail.ru/oauth/token",
      profile_url=> "https://www.appsmail.ru/platform/api",
      profile_query => sub {
        my ($c, $auth, ) = @_;
        my $param = {
          method=>'users.getInfo',
          app_id=>$Init->config->{mailru}{key},
          session_key=>$auth->{access_token},
          #~ uids=>$auth->{x_mailru_vid},
          secure=>1,
        };
        $param->{sig} = md5_hex map("$_=$param->{$_}", sort keys %$param), $Init->config->{mailru}{secret};
        $param;
      },
      profile_avatar =>'pic_small',

    }
  }
  
};

has config => sub {# только $Init ! имя providers уже занято
  my $self = shift;
  
  while (my ($name, $val) = each %{$self->{providers}}) {
    my $site = $self->model->site( json_enc($val), $name,);
    @$val{qw(id)} = @$site{qw(id)};
    $val->{name} = $name;
  }
  merge $self->{providers}, $self->_providers;
};

has curr_profile => sub { shift->${ \$Init->plugin->merge_conf->{auth}{current_user_fn} };};

has ua => sub {shift->app->ua->connect_timeout(30);};

#~ sub curr_profile { shift->${ \$Init->plugin->merge_conf->{auth}{current_user_fn} };};

sub init {# from plugin
  state $self = shift->SUPER::new(@_);
  
  die "Plugin OAuth2 already loaded"
    if $self->app->renderer->helpers->{'oauth2.get_token'};
  
  #~ $self->app->log->debug($self->app->dumper($self->config));
  $self->app->plugin("OAuth2::Che" => $self->config);
  
  $Init = $self;
  return $self;
  
}

sub login {
  my $c = shift;
  
  my $referrer =  $c->req->headers->referrer && Mojo::URL->new($c->req->headers->referrer)->path || 'profile';
  my $redirect = $c->param('redirect') || $referrer;
  
  my $site_name = $c->stash('site');

  my $site = $c->oauth2->providers->{$site_name}
    or return $c->redirect_to($c->url_for($referrer)->query(error=> "No such oauth provider [$site_name]"));
    #~ or return $c->render('profile/index', err=>);
  
  if (my @fatal = grep !defined $site->{$_}, qw(id key secret authorize_url token_url profile_url profile_query)) {
    #~ die "OAuth provider [$site_name] does not configured: [@fatal] is not defined";
    return $c->redirect_to($c->url_for($referrer)->query(error=> "OAuth provider [$site_name] does not configured: [@fatal] is not defined"));
  }
  
  my $curr_profile = $c->curr_profile;
  
  my $r; $r = $Init->model->check_profile($curr_profile->{id}, $site->{id})
    and $c->app->log->warn("Попытка двойной авторизации сайта $site_name", $c->dumper($r), "профиль: ", $c->dumper($curr_profile),)
    #~ and return $c->redirect_to($c->url_for(${ delete $c->session->{oauth_init} }{redirect})->query(err=> "Уже есть авторизация сайта $site_name"))
    and return $c->redirect_to($c->url_for($referrer)->query(error=> "Уже есть авторизация сайта $site_name"))
    if $curr_profile;
  
  $c->session(oauth_init => {
    site => $site_name,
    referrer => $referrer, # failback
    redirect => $redirect, # success
  })
    unless $c->session('oauth_init');

  $c->delay(
    sub { # шаг авторизации
      my $delay = shift;
      my $args = {
        redirect_uri => $c->url_for('oauth-login', site=>$site_name)->userinfo(undef)->to_abs,
        $site->{authorize_query} ? (authorize_query => $site->{authorize_query}) : (),
      };
      $c->oauth2->get_token($site_name => $args, $delay->begin);
    },
    sub {# ну-ка профиль
      my ($delay, $err, $auth) = @_;
      $err .= json_enc($auth->{error})
        if $auth->{error};
      
      $c->app->log->error("Автоизация $site_name:", $err, $c->dumper($auth))
        #~ and return $c->$fail_auth_cb()
        and return $c->redirect_to($c->url_for(${ delete $c->session->{oauth_init} }{referrer})->query(error=> $err." Нет access_token"))
        unless $auth->{access_token};
      
      my $url = Mojo::URL->new($site->{profile_url})->query($c->${ \$site->{profile_query} }($auth));
      
      $c->ua->get($url, $delay->begin);
      $delay->pass($auth);
    },
    sub {# профиль сайта получен
      my ($delay, $tx, $auth) = @_;
      
      my $profile = $c->_process_profile_tx($site, $auth, $tx);
      
      #~ $c->session(oauth_err => $profile)
        #~ and
      my $oauth_init = delete $c->session->{oauth_init};
      return $c->redirect_to($c->url_for($oauth_init->{referrer})->query(error=> $profile, site=>$oauth_init->{site}))#
        unless ref $profile;

      return $c->redirect_to($c->url_for($oauth_init->{redirect}));#
      #~ $c->redirect_to(${ delete $c->session->{oauth_init} }{redirect});
    },
  ); # end delay
  
}

sub _process_profile_tx {# $auth->{conflict} = 'old' нужен для мобильного приложения в редактировании привязок к сайтам, т.е. не допустить использования внешнего профиля привязанного в другом аккаунте
  my $c = shift;
  my ($site, $auth, $tx) = @_;
  my $curr_profile = $c->curr_profile;
  if (my $auth_cookie = delete $auth->{auth_cookie}) {
    $curr_profile ||= $c->access->auth_cookie($c, $auth_cookie);
  }
  my ($data, $err) = $c->oauth2->process_tx($tx);
  $err .= json_enc($data->{error})
    if ref($data) eq 'HASH' && $data->{error};
  $c->app->log->error("Ошибка профиля сайта $site->{name}:", $err, $tx->req->url, $c->dumper($tx->res), $c->dumper($data),)
    and return $err
    if $err;
  
  $data = $data->{response}
    if ref($data) eq 'HASH' && $data->{response};
  $data = shift @$data
    if ref $data eq 'ARRAY';
  @$data{keys %$auth} = values %$auth;
  
  my @bind = (json_enc($data), $site->{id}, $auth->{uid} || $auth->{user_id} || $data->{uid} || $data->{id} || $data->{user_id});
  
  my $oau = $Init->model->user(@bind);
  
  $c->app->log->error("Конфликт использования внешнего профиля, уже привязан в другом профиле")
    #~ and return "Вход на сайт через [$site->{name}] пользователя #$oau->{user_id} уже используется. Невозможно привязать дважды. Можно <a href='/logout?redirect=@{[$c->url_for('oauth-login', site=>$site->{name})]}' class='relogin'>переключиться</a> на этот вход."
    and return 'CONFLICT'
    if $oau->{old} && $curr_profile;
  
  my $profile = 
      
        $curr_profile
        
        || $Init->model->profile($oau->{id}) # по внешнему профилю получить наш профиль

        || $Init->plugin->model('Profiles')->new_profile([$data->{first_name} || $data->{given_name}, $data->{last_name} || $data->{family_name},]);
  
  
  $c->authenticate(undef, undef, $profile) # session only store
    unless $curr_profile;
  
  my $r = $Init->plugin->model('Refs')->refer($profile->{id}, $oau->{id},);
  
  return $profile;
  
}


sub oauth_profile {# получить по access_token
  my $c = shift;
  my $site_name = $c->stash('site');
  my $site = $c->oauth2->providers->{$site_name}
    or return $c->render(json=>{error=>"No such oauth provider [$site_name]"});
  my $auth = $c->req->json
    or return $c->render(json=>{error=>"Must send JSON auth data"});
  return $c->render(json=>{ error=>"JSON data access_token not defined"})
    unless $auth->{'access_token'};
  
  $c->delay(
    sub {# ну-ка профиль
      my ($delay) = @_;
      
      my $url = Mojo::URL->new($site->{profile_url})->query($c->${ \$site->{profile_query} }($auth));
      
      $c->ua->get($url, $delay->begin);
      #~ $delay->pass($auth);
    },
    sub {# профиль сайта получен
      my ($delay, $tx,) = @_;
      
      my $profile = $c->_process_profile_tx($site, $auth, $tx);
      
      return $c->render(json=>{ error=>$profile })
        unless ref $profile;
      
      #~ $c->authenticate(undef, undef, $profile) # mobile app
        #~ unless $c->curr_profile;
      
      my $ou = $Init->model->oauth_users_by_profile($profile->{id});
      my $oprofile = json_dec $ou->{$site_name}{profile};
      delete @$oprofile{qw(user_id access_token expires_in token_type refresh_token id_token)};
      $c->render(json=>$oprofile);
    },
  );
  
}

sub detach {# отсоединить
  my $c = shift;
  my $referrer =  $c->req->headers->referrer && Mojo::URL->new($c->req->headers->referrer)->path || 'profile';
  my $redirect = $c->param('redirect') || $referrer;
  my $site_name = $c->stash('site');
  
  my $is_post = uc($c->req->method) eq 'POST';

  my $site = $c->oauth2->providers->{$site_name}
    or ($is_post && return $c->render(json=>{error =>"No such oauth provider [$site_name]"}))
    or return $c->redirect_to($c->url_for($referrer)->query(error => "No such oauth provider [$site_name]"));
  
  my $curr_profile = $c->curr_profile;
  
  my $r = $Init->model->detach($site->{id}, $curr_profile->{id},);
  #~ $c->app->log->debug("Убрал авторизацию сайта [$site_name] профиля [$curr_profile->{id}]", $c->dumper($r));
  
  $Init->plugin->model('Refs')->del($r->{ref_id}, undef, undef);
  
  $is_post && return $c->render(json=>{success=>"detach [$site_name]"});
  
  #~ my $redirect = $c->param('redirect') || ($c->req->headers->referrer && Mojo::URL->new($c->req->headers->referrer)->path) || 'profile';
  return $c->redirect_to($redirect);
}

#~ sub out {# выход
  #~ my $c = shift;
  #~ $c->logout;
  #~ $c->redirect_to($c->param('redirect') || '/');
#~ }

sub _routes {# from plugin!
  my $self = shift;
  
  return (
  
  {request=>'/oauth/login/:site',
    namespace => $Init->namespace,
    controller => $Init->controller,
    action => 'login',
    name => 'oauth-login',
  },
  {request=>'POST /oauth/profile/:site',
    namespace => $Init->namespace,
    controller => $Init->controller,
    action => 'oauth_profile',
    name => 'oauth profile',
  },
  {request=>'/oauth/detach/:site',
    namespace => $Init->namespace,
    controller=>$Init->controller,
    action => 'detach',
    name => 'oauth-detach',
    auth=>'only',
  },
  {request=>'GET /oauth/data',
    namespace => $Init->namespace,
    controller=>$Init->controller,
    action => 'oauth_data',
    name => 'oauth data',
  },
  
  #~ {request =>'/logout',
    #~ namespace => $Init->namespace,
    #~ controller => $Init->controller,
    #~ action => 'out',
    #~ name => 'logout',
  #~ },
  {request =>'/'.$Init->plugin->admin->trust."/oauth/conf",
    namespace => $Init->namespace,
    controller => $Init->controller,
    action => 'conf',
    name => 'oauth-conf',
  }
  
  );
  
}

sub conf {
  my $c = shift;
    $c->render(format=>'txt', text=>
     "PROVIDERS\n---\n"
    . $c->dumper(($c->oauth2->providers))
  );
}

sub oauth_data {
  my $c = shift;
  my $uid = $c->curr_profile && $c->curr_profile->{id};
  my $ou = $Init->model->oauth_users_by_profile($uid)
    if $uid;
  
  my @data = map {
    my %site = %$_;
    delete @site{qw(secret profile_query authorize_url token_url profile_url authorize_query scope)};
    if ($ou) {# already authenticate
      my $oauth = $ou->{$site{name}} || {};# по имени сайта
      my $profile = $oauth->{profile};
      
      $site{profile} = json_dec($profile)
        #~ and delete(@$oauth{qw(ts profile_ts)})
        and delete (@{$site{profile}}{qw(user_id access_token id_token expires_in token_type refresh_token)})
        if $profile;
    } else {# needs authenticate
      #~ $site{authenticate}=1;
    }
    
    #~ $oauth->{site_name} ||= $_->{name};
    #~ $oauth; # || {}
    \%site;
    
  } grep($_->{id}, values %{$c->oauth2->providers});
  
  $c->render(json=>\@data);
}

1;

=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::RoutesAuthDBI::OAuth

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::OAuth - is a Mojolicious::Controller for oauth2 logins to project. Its has two route: for login and logout.

=head1 DB DESIGN DIAGRAM

See L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/blob/master/Diagram.svg>

=head1 SYNOPSIS

    $app->plugin('RoutesAuthDBI', 
        ...
        oauth => {< hashref options list below >},
        ...
    );

=head2 OPTIONS

=head3 namespace

Namespace (string). Defaults to 'Mojolicious::Plugin::RoutesAuthDBI'.

=head3 controller

Module controller name. Defaults to 'OAuth'.


=head3 providers

Hashref for key/value per each need provider. Required.

  providers => {google=>{key=> ..., secret=>..., }, ...},

See L<Mojolicious::Plugin::OAuth2>. But two additional parameters (keys of provider hash) are needs:

=head4 profile_url

Abs url string to fetch profile info after success oauth.

  profile_url=> 'https://www.googleapis.com/oauth2/v1/userinfo',

=head4 profile_query

Coderef which prepare additional query params for C<profile_url>

Example for google:

  profile_query => sub {
    my ($c, $auth, ) = @_;
    {
      alt => 'json',
      access_token => $auth->{access_token},
    };
  },

In: $auth hash ref with access_token.

Out: hashref C<profile_url> query params.

=head3 tables

Hashref of any DB tables names. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.

=head2 Defaults options for oauth:

  oauth = > {
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    module => 'OAuth',
  },

disable oauth module
  
  oauth => undef, 
  

=head1 METHODS NEEDS IN PLUGIN

=head2 _routes()

This oauth controller routes. Return array of hashrefs routes records for apply route on app. Plugin internal use.

=head1 ROUTES

There are number of app routes on this controller:

=head2 /oauth/login/:site

Main route of this controller. Stash B<site> is the name of the hash key of the C<providers> config above. Example html link:

  <a href="<%= $c->url_for('oauth-login', site=> 'google')->query(redirect=>'profile') %>">Login by google</a>

This route has builtin name 'oauth-login'. This route accept param 'redirect' and will use for $c->redirect_to after success oauith and also failed oauth clauses with param 'err'.

=head2 /oauth/detach/:site

Remove attached oauth user to profile. Stash B<site> and param 'redirect' as above. Route has builtin name 'oauth-detach'.

=head2 /oauth/data

Get remote oauth data site only configured.

=head2 POST /oauth/profile/:site

Usefull for cordova mobile app oauth connect.

IN: json data C<{access_token=>"..."}> that got from oauth B<authorize_url> API request.

OUT: stored remote oauth API profile.

=head2 <trust admin option>/oauth/conf

The L<Mojolicious::Plugin::RoutesAuthDBI::Admin/"trust"> option.

Returns text dump current hash of L<Mojolicious::Plugin::OAuth2/"providers">.

=head1 SEE ALSO

L<Mojolicious::Plugin::RoutesAuthDBI>

L<Mojolicious::Plugin::RoutesAuthDBI::Admin>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

