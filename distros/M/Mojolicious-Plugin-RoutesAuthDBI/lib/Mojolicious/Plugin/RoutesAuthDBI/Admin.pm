package Mojolicious::Plugin::RoutesAuthDBI::Admin;
use Mojo::Base 'Mojolicious::Controller';
#~ use Mojo::Util qw(md5_sum);

my $pkg = __PACKAGE__;
my ($Init);
has [qw(plugin controller namespace prefix trust role_admin)];

sub init {# from plugin! init Class vars
  state $self = shift->SUPER::new(@_);
  $Init = $self;
  return $self;
}


sub index {
  my $c = shift;
  no warnings;
  $c->render(format=>'txt', text=><<TXT)
$pkg

You are signed as:
@{[$c->dumper( $c->auth_user)]}


ADMIN ROUTES (this controller)
===

@{[map "$_->{request}\t\t$_->{descr}\n", $c->self_routes]}

TXT
    and return
    if $c->is_user_authenticated;
  
  $c->render(format=>'txt', text=>__PACKAGE__."\n\nYou are not signed!!!\n\nTo sign in go to /sign/in/<login>/<pass>\n");
}

sub sign {
  my $c = shift;
  
  $c->authenticate($c->vars(qw'login pass'))
    and $c->redirect_to("admin home")
    #~ and $c->render(format=>'txt', text=>__PACKAGE__ . "\n\nSuccessfull signed! ".$c->dumper( $c->auth_user))
    and return;
    
  
  $c->render(format=>'txt', text=>__PACKAGE__ . "\n\nBad sign! Try again");
}

sub signout {
  my $c = shift;
  
  $c->logout;
  
  $c->render(format=>'txt', text=>__PACKAGE__ . "\n\nYou are exited!!!");
  
}

sub out {# выход с редиректом
  my $c = shift;
  $c->logout;
  $c->redirect_to($c->param('redirect') || '/');
}

sub users {
  my $c = shift;
  
  my $p = $Init->plugin->model('Profiles')->profiles;
  $c->render(format=>'txt', text=><<TXT)
$pkg

Profiles(@{[scalar @$p]})
===

@{[$c->dumper( $p)]}
TXT
}

sub new_user {
  my $c = shift;
  
  my ($login, $pass) = $c->vars(qw'login pass');
  
  my $r;
  ($r = $Init->plugin->model('Profiles')->get_profile(undef, $login))
    and $c->render(format=>'txt', text=><<TXT)
$pkg

Profile/User already exists
===

@{[$c->dumper( $r)]}
TXT
    and ($r->{not_new} = '!')
    and return $r;
  
  $r = $Init->plugin->model('Logins')->new_login($login, $pass);
  
  my $p = $Init->plugin->model('Profiles')->new_profile([$login],);
  
  $Init->plugin->model('Refs')->refer($p->{id} => $r->{id});
  
  @$p{qw(login pass)} = @$r{qw(login pass)};
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success sign up new profile/user
===

@{[$c->dumper( $p)]}
TXT
  return $p;
}

sub trust_new_user {
  my $c = shift;
  
  my $u = $c->new_user;
  
  # ROLE
  my $rl = $Init->plugin->model('Roles')->get_role(undef, $Init->role_admin || $Init->controller)
    || $Init->plugin->model('Roles')->new_role($Init->role_admin || $Init->controller);
  
  # REF role->user
  my $ru = $Init->plugin->model('Refs')->refer($rl->{id} => $u->{id});
  
  # CONTROLLER
  my $cc = $Init->plugin->model('Controllers')->controller_ns($Init->{controller}, ($Init->{namespace}) x 2,)
    || $Init->plugin->model('Controllers')->new_controller($Init->{controller}, 'admin actions');
  
  #Namespace
  my $ns = $Init->plugin->model('Namespaces')->namespace(undef, $Init->{namespace},)
    || $Init->plugin->model('Namespaces')->new_namespace($Init->{namespace}, 'plugin ns!', undef, undef,);
  
  #ref namespace -> controller
  my $nc = $Init->plugin->model('Refs')->refer($ns->{id}, $cc->{id});
  
  #REF namespace->role
  my $cr = $Init->plugin->model('Refs')->refer($ns->{id}, $rl->{id});
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success sign up new trust-admin-user with whole access to namespace=[$Init->{namespace}]
===

USER:
@{[$c->dumper( $u)]}

ROLE:
@{[$c->dumper( $rl)]}

CONTROLLER:
@{[$c->dumper( $cc)]}

NAMESPACE:
@{[$c->dumper( $ns)]}

TXT
}

sub new_role {
	my $c = shift;
	my ($name) = $c->vars('name');
	my $r = $Init->plugin->model('Roles')->get_role(undef, $name);
	$c->render(format=>'txt', text=><<TXT)
$pkg

Role exists
===

@{[$c->dumper( $r)]}

TXT
		and return $c
		if $r;
	$r = $Init->plugin->model('Roles')->new_role($name);
	
	$c->render(format=>'txt', text=><<TXT);
$pkg

Success created role
===

@{[$c->dumper( $r)]}

TXT
	
}

sub user_roles {
  my $c = shift;
  my ($user) = $c->vars(qw'user login');# || $c->vars('login');
  my $u =  $Init->plugin->model('Profiles')->get_profile($user =~ /\D/ ? (undef, $user) : ($user, undef,));
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such profile.id/login [$user]
===

TXT
    and return
    unless $u;
  
  my $r = $u->roles;
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

PROFILE+LOGIN
---
@{[$c->dumper( $u)]}

List of profile/login roles (@{[scalar @$r]})
===

ROLES
---
@{[$c->dumper( $r)]}

TXT
  
}

sub roles {
  my $c = shift;
  my $r = $Init->plugin->model('Roles')->roles;
  $c->render(format=>'txt', text=><<TXT);
$pkg

ROLES(@{[scalar @$r]})
===
---
@{[$c->dumper( $r)]}

TXT
}

sub new_role_user {
  my $c = shift;
  
  my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->get_role($role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

Can't create new role by only digits[$role] in name
===

TXT
    and return
    unless $r && $role =~ /\w/;
  $r ||= $Init->plugin->model('Roles')->new_role($role);
  
  my ($user) = $c->vars('user');
  my $u = $Init->plugin->model('Profiles')->get_profile($user =~ /\D/ ? (undef, $user) : ($user, undef,));
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such profile.id/login [$user]
===

TXT
    and return
    unless $u;
  
  my $ref = $Init->plugin->model('Refs')->refer($r->{id} => $u->{id});
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success assign ROLE[$r->{name}] -> USER [@{[$c->dumper( $u) =~ s/\s+//gr]}]
===

@{[$c->dumper( $ref)]}
TXT
  
}

# доступ к контроллеру
sub new_role_controller {
  my $c = shift;
  
  my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->get_role($role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

Can't create new role by only digits[$role] in name
===

TXT
    and return
    unless $r && $role =~ /\w/;
  $r ||= $Init->plugin->model('Roles')->new_role($role);
  
  my ($ns, $controll) = $c->vars(qw'ns controll');
  my $cntr = $Init->plugin->model('Controllers')->controller_id_ns($controll =~ /\D/ ? (undef, $controll) : ($controll, undef), $ns && $ns =~ /\D/ ? (undef, $ns) : ($ns, undef), $ns);
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such controller [$ns::$controll]
===

TXT
    and return
    unless $cntr;
  
  my $ref = $Init->plugin->model('Refs')->refer($cntr->{id} => $r->{id},);
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success assign access

CONTROLLER 
===
@{[$c->dumper( $cntr) ]}

ROLE
===
@{[$c->dumper( $r)]}

REF
===
@{[$c->dumper( $ref)]}
TXT
}

sub del_role_user {# удалить связь пользователя с ролью
  my $c = shift;
  
  my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->get_role($role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such role [$role]
===

TXT
    and return
    unless $r;

  my ($user) = $c->vars('user');
  my $u = $Init->plugin->model('Profiles')->get_profile($user =~ /\D/ ? (undef, $user) : ($user, undef,));
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such profile.id/login [$user]
===

TXT
    and return
    unless $u;
  
  my $ref = $Init->plugin->model('Refs')->del(undef, $r->{id}, $u->{id});
  $c->render(format=>'txt', text=><<TXT)
$pkg

Success delete ref ROLE[$r->{name}] -> USER[@{[$c->dumper( $u) =~ s/\s+//gr]}]
===

@{[$c->dumper( $ref)]}
TXT
    and return
    if $ref;
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

There is no ref ROLE[$r->{name}] -> USER[@{[$c->dumper( $u) =~ s/\s+//gr]}]

TXT
  
}

sub disable_role {
  my $c = shift;
  my $a = shift // 1; # 0-enable 1 - disable
  my $k = {0=>'enable', 1=>'disable',};
  
  my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->dsbl_enbl($a, $role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such role [$role]
===

TXT
    and return
    unless $r;
  
  $c->render(format=>'txt', text=><<TXT)
$pkg

Success @{[$k->{$a}]} role
===

@{[$c->dumper( $r)]}

TXT
}

sub enable_role {shift->disable_role(0);}


sub role_users {# все пользователи роли по запросу /myadmin/users/:role
  my $c = shift;
  
  my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->get_role($role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such role [$role]
===

TXT
    and return
    unless $r;
  
  my $u = $Init->plugin->model('Roles')->profiles($r->{id});
  $c->render(format=>'txt', text=><<TXT);
$pkg

Profile/users(@{[scalar @$u]}) by role [$r->{name}]
===

@{[$c->dumper( $u)]}
TXT
}

sub role_routes {# все маршруты роли по запросу /myadmin/routes/:role
  my $c = shift;
  
   my ($role) = $c->vars('role');
  # ROLE
  my $r = $Init->plugin->model('Roles')->get_role($role =~ /\D/ ? (undef, $role) : ($role, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

No such role [$role]!

TXT
    and return
    unless $r;
  
  my $t = $Init->plugin->model('Routes')->routes_ref($r->{id});
  $c->render(format=>'txt', text=><<TXT);
$pkg

Total @{[scalar @$t]} routes by role [$r->{name}]

@{[$c->dumper( $t)]}
TXT
}

sub controllers {
  my $c = shift;
  my $list = $Init->plugin->model('Controllers')->controllers;
  $c->render(format=>'txt', text=><<TXT);
$pkg

CONTROLLERS (@{[scalar @$list]})
===

@{[$c->dumper( $list)]}
TXT
}

sub controll {# /controller/:ns/:controll
  my $c = shift;
  my ($ns, $controll) = $c->vars(qw(ns controll));
  my $r = $Init->plugin->model('Controllers')->controller_id_ns($controll =~ /\D/ ? (undef, $controll) : ($controll, undef), $ns && $ns =~ /\D/ ? (undef, $ns) : ($ns, undef), $ns);
  $c->render(format=>'txt', text=><<TXT);
$pkg

CONTROLLER
===

@{[$c->dumper( $r)]}
TXT
}

sub new_controller {
  my $c = shift;
  #~ my $ns = $c->stash('ns') || $c->param('ns') ||  $c->stash('namespace') || $c->param('namespace');
  my ($ns) = $c->vars(qw'ns namespace');# || ($c->vars('namespace'));
  my ($mod) = $c->vars(qw'module controll');
  my ($descr) = $c->vars(qw'descr');
  my $cn = $Init->plugin->model('Controllers')->controller_ns($mod, ($ns) x 2,);
  $c->render(format=>'txt', text=><<TXT)
$pkg

Controller already exists
===

@{[$c->dumper( $cn)]}
TXT
  and return
  if $cn;
  my $n = $c->new_namespace($ns) if $ns;
  $cn = $Init->plugin->model('Controllers')->new_controller($mod, $descr);
  $Init->plugin->model('Refs')->refer($n->{id}, $cn->{id})
    if $n;
  
  $cn = $Init->plugin->model('Controllers')->controller_ns($mod, ($ns) x 2,);
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success create new controller
===

@{[$c->dumper( $cn)]}
TXT
  return $cn;
}

sub namespaces {
  my $c = shift;
  my $list = $Init->plugin->model('Namespaces')->namespaces;
  $c->render(format=>'txt', text=><<TXT);
$pkg

Namespaces (@{[scalar @$list]})
===

@{[$c->dumper( $list)]}
TXT
}

sub new_namespace {
  my $c = shift;
  my ($ns) = $_[0] ? (shift) : $c->vars('ns');
  my ($descr) = $_[0] ? (shift) :  $c->vars('descr');
  my ($app_ns) = $_[0] ? (shift) : $c->vars('app_ns');
  my ($interval_ts) = $_[0] ? (shift) : $c->vars('interval_ts');
  my $n = $Init->plugin->model('Namespaces')->namespace($ns =~ /\D/ ? (undef, $ns) : ($ns, undef,));
  $c->render(format=>'txt', text=><<TXT)
$pkg

Namespace already exists
===

@{[$c->dumper( $n)]}
TXT
  and return $n
  if $n;
  $n = $Init->plugin->model('Namespaces')->new_namespace($ns, $descr, $app_ns, $interval_ts);
  $c->render(format=>'txt', text=><<TXT);
$pkg

Success create new namespace
===

@{[$c->dumper( $n)]}
TXT
  return $n;
  
}

sub actions {
  my $c = shift;
  my $list = $Init->plugin->model('Actions')->actions;
  map {
    $_->{routes} = $Init->plugin->model('Routes')->routes_action($_->{id});
  } @$list;
  $c->render(format=>'txt', text=><<TXT);
$pkg

ACTIONS list (@{[scalar @$list]})
===

@{[$c->dumper( $list )]}
TXT
}

sub routes {
  my $c = shift;
  my $list = $Init->plugin->model('Routes')->routes;
  
  $c->render(format=>'txt', text=><<TXT);
$pkg

ROUTES (@{[scalar @$list]})
===

@{[$c->dumper( $list )]}
TXT
}

sub new_route_ns {# показать список мест-имен
  my $c = shift;
  my $list = $Init->plugin->model('Namespaces')->namespaces;
  $c->render(format=>'txt', text=><<TXT);
$pkg

1. Для нового маршрута укажите имя namespace или его ID или undef.
Новый можно ввести.

Namespaces (@{[scalar @$list]})
===

@{[$c->dumper( $list )]}
TXT
}

sub new_route_c {# показать список контроллеров
  no warnings;
  my $c = shift;
  my ($ns) = $c->vars('ns');
  $ns = $Init->plugin->model('Namespaces')->namespace($ns && $ns =~ /\D/ ? (undef, $ns) : ($ns, undef,))
    || {namespace => $ns};
  my $list = $Init->plugin->model('Controllers')->controllers_ns_id(($ns->{id}) x 2);
  $c->render(format=>'txt', text=><<TXT);
$pkg

1. namespace = [@{[$c->dumper( $ns )]}]

Указать имя или ID контроллера или ввести новое имя

Если указать undef для последующей неявной привязкой через параметр маршрута - "to"

Controllers (@{[scalar @$list]})
===

@{[$c->dumper( $list )]}
TXT
}

sub new_route_a {# показать список действий
  no warnings;
  my $c = shift;
  my ($ns, $controll) = $c->vars(qw'ns controll');
  
  $ns = ($ns && $Init->plugin->model('Namespaces')->namespace($ns && $ns =~ /\D/ ? (undef, $ns) : ($ns, undef,)))
    || {namespace => $ns};
  
  $controll = ($controll && $Init->plugin->model('Controllers')->controller_id_ns($controll =~ /\D/ ? (undef, $controll) : ($controll, undef,), $ns->{id}, $ns->{namespace}, $ns->{namespace},))
    || {controller=>$controll};
  
  my $list = $controll->{id} ? $Init->plugin->model('Actions')->actions_controller($controll->{id}) : ['контроллер пропускается'];
  my $list2 = $Init->plugin->model('Actions')->actions_controller_null();
  $c->render(format=>'txt', text=><<TXT);
$pkg

1. namespace = [@{[$c->dumper( $ns )]}]
2. controller = [@{[$c->dumper( $controll )]}]

Указать имя или ID действия из списка или ввести новое имя действия

Или указать undef чтобы привязать маршрут к контроллеру или вообще неявно через параметр route"to", но тогда на следующем шаге обязательно указать параметр to=->имя метода в котроллере 

Actions for selected controller (@{[scalar @$list]})
===
@{[$c->dumper( $list )]}

Actions without controller (@{[scalar @$list2]}):
===
@{[$c->dumper( $list2 )]}

TXT
}

my @route_cols = qw(request host_re to name descr auth disable interval_ts);
sub new_route {# показать маршруты к действию
  my $c = shift;
  my ($ns, $controll, $act) = $c->vars(qw'ns controll act');
  
  $ns = ($ns && $Init->plugin->model('Namespaces')->namespace($ns&& $ns =~ /\D/ ? (undef, $ns) : ($ns, undef,)))
    || {namespace => $ns};
  
  $controll = ($controll && $Init->plugin->model('Controllers')->controller_id_ns($controll =~ /\D/ ? (undef, $controll) : ($controll, undef,), $ns->{id}, $ns->{namespace}, $ns->{namespace},))
    || {controller=>$controll};
  
  $act = ($act && $Init->plugin->model('Actions')->action_controller($controll->{id}, $act =~ /\D/ ? (undef, $act) : ($act, undef,),))
    || ($act && $Init->plugin->model('Actions')->action_controller_null($act =~ /\D/ ? (undef, $act) : ($act, undef,),))
    || {action => $act};
  
  # Проверка на похожий $request ?? TODO
  my $route = {};
  @$route{@route_cols, 'id'} = $c->vars(@route_cols, 'id',);

  my @save = ();
  ($route->{id} || ($route->{request} && $route->{name}))
    && (@save = $c->route_save($ns, $controll, $act, $route))
    && $c->render(format=>'txt', text=><<TXT)
$pkg

Success done save!

Namespace:
===
@{[$c->dumper( $save[0] )]}

Controller:
===
@{[$c->dumper( $save[1] )]}

Action:
===
@{[$c->dumper( $save[2] )]}

Route:
===
@{[$c->dumper( $save[3] )]}

Refs:
===
@{[$c->dumper( $save[4] )]}

TXT
    && return $c
  ;
  
  
  # маршруты действия
  my $list = $act->{id} ? $Init->plugin->model('Routes')->routes_action($act->{id})
    : ['нет явного действия'];
  # свободные маршруты
  my $list2 = $Init->plugin->model('Routes')->routes_action_null;
  
  no warnings;
  $c->render(format=>'txt', text=><<TXT);
$pkg

1. namespace = [@{[$c->dumper( $ns )]}]
2. controller = [@{[$c->dumper( $controll )]}]
3. action = [@{[$c->dumper( $act )]}]

Маршрут: 
@{[$c->dumper( $route )]}

Указать параметры маршрута (?request=/x/y/:z&name=xyz&descr=...):

* request (request=GET POST /foo/:bar)
* name (name=foo_bar)
- host_re (regexp for HeaderCondition plugin)
- to (to=Foo->bar or to=->bar)
- descr (descr=пояснение такое)
- auth (auth=1) (auth='only')
- disable (disable=1)
- interval_ts (interval_ts=123)

Exists routes for selected action (@{[scalar @$list ]})
===
@{[$c->dumper( $list )]}

Free routes (@{[scalar @$list2]})
===
@{[$c->dumper( $list2 )]}

TXT
  
}

sub route_save {
  my $c = shift;
  my ($ns, $controll, $act, $route) = @_;
  #~ local $Init->plugin->dbh->{AutoCommit} = 0;
  $ns = $Init->plugin->model('Namespaces')->new_namespace(@$ns{qw(namespace descr app_ns interval_ts)})
    if $ns->{namespace} && ! $ns->{id};
  $controll = $Init->plugin->model('Controllers')->new_controller(@$controll{qw(controller descr)})
    if $controll->{controller} && !$controll->{id};
  $act = $Init->plugin->model('Actions')->new_action(@$act{qw(action callback descr)})
    if $act->{action} && !$act->{id};
  
  $route->{to} =~ s/->/#/
    if $route->{to};
  
  $route = $Init->plugin->model('Routes')->new_route(@$route{@route_cols})
    unless $route->{id};
  my $ref = [map {
    $Init->plugin->model('Refs')->refer($$_[0]{id}, $$_[1]{id},)
      if $$_[0]{id} && $$_[1]{id};
  } ([$ns, $controll], [$controll, $act], [ $act, $route,], $act->{id} ? () : [$controll, $route,])];
  #~ $Init->plugin->dbh->commit;
  return ($ns, $controll, $act, $route, $ref);

}

sub vars {# получить из stash || param
  my $c = shift;

  return map {
    my $var = $c->stash($_) || $c->param($_);
    $var = undef if defined($var) && $var eq 'undef';
    $var;
  } @_;
}

my @self_routes_cols = qw(request action name auth descr);
sub self_routes {# from plugin!
  my $c = shift;
  my $prefix = $Init->prefix;
  my $trust = $Init->trust;
  my $role_admin = $Init->role_admin;

  my $t = <<TABLE;
#format
#<route path>\t<method>\t<route name>\t<need auth>\tDescription
/$prefix	index	admin home	1	Main page
#
# Namespaces, controllers, actions
#
/$prefix/namespaces	namespaces	$prefix namespaces	1	Namespaces list
/$prefix/namespace/new/:ns/:descr/:app_ns	new_namespace	$prefix new_namespace	1	Add new ns
/$prefix/controllers	controllers	$prefix controllers	1	Controllers list
/$prefix/controller/new/:ns/:module	new_controller	$prefix new_controller	1	Add new controller by :ns and :module
/$prefix/controller/:ns/:controll	controll	$prefix controller	1	View a controller (ID and name for NS and controller)
/$prefix/actions	actions	$prefix actions	1	Actions list
#
# Роли и доступ
#
/$prefix/role/new/:name	new_role	$prefix create role	1	Add new role by :name
/$prefix/role/del/:role/:user	del_role_user	$prefix del ref role->user	1	Delete ref :user -> :role by user.id|user.login and role.id|role.name.
/$prefix/role/dsbl/:role	disable_role	$prefix disable role->user	1	Disable :role by role.id|role.name.
/$prefix/role/enbl/:role	enable_role	$prefix enable role->user	1	Enable :role by role.id|role.name.
/$prefix/roles	roles	$prefix view roles	1	View roles table
/$prefix/roles/:user	user_roles	$prefix roles of user	1	View roles of :user by profile.id|login
/$prefix/role/user/:role/:user	new_role_user	$prefix create ref role->profile	1	Assign :user to :role by profile.id|login and role.id|role.name.
/$prefix/role/namespace/:role/:ns	new_role_namespace	$prefix create ref namespace->role	1	Assign :role to :ns by role.id|role.name and namespace.id|namespace.name.
/$prefix/role/controller/:role/:ns/:controll	new_role_controller	$prefix create ref controller->role	1	Assign :role to :controll by role.id|role.name and controller.id|controller.name+namespace(id|name).
#
# Последовательный ввод нового маршрута
#
/$prefix/route/new	new_route_ns	$prefix create route step ns	1	Step namespace
/$prefix/route/new/:ns	new_route_c	$prefix create route step controll	1	Step controller
/$prefix/route/new/:ns/:controll	new_route_a	$prefix create route step action	1	Step action
/$prefix/route/new/:ns/:controll/:act	new_route	$prefix create route step request	1	Step request. Params: request, name, auth, descr, ....
/$prefix/route/new/:ns/:controll/:act/:id	new_route	$prefix create route step exist route	1	Step by route id to assign to ns-controller-action
#
# Маршруты и доступ
#
/$prefix/routes	routes	$prefix view routes	1	View routes list
/$prefix/routes/:role	role_routes	$prefix routes of role	1	All routes of :role by id|name
/$prefix/route/:route/:role	ref	$prefix create ref route->role	1	Assign :route with :role by route.id and role.id|role.name
#
# Пользователи/профили
#
/$prefix/user/new	new_user	$prefix create user	1	Add new user by params: login,pass,...
/$prefix/user/new/:login/:pass	new_user	$prefix create user st	1	Add new user by :login & :pass
/$prefix/users	users	$prefix view users	1	View users table
/$prefix/users/:role	role_users	$prefix users of role	1	View users of :role by id|name
#
#get foo /sign/in	sign	signin form	0	Login&pass form
#post /sign/in	sign	signin params	0	Auth by params
/$prefix/sign/in/:login/:pass	sign	signin stash	0	Auth by stash
/$prefix/sign/out	signout	go away	only	Exit
/logout	out	logout	only	Exit and redirect
/reauth/:cookie	auth_cookie	auth-cookie	0	Relogin by cookie
#

/$prefix/$trust/$role_admin/new/:login/:pass	trust_new_user	$prefix/$trust !trust create user!	0	Add new user by :login & :pass and auto assign to role 'Admin' and assign to access this controller!

TABLE
  
  
  my @r = ();
  for my $line (grep /\S+/, split /\n/, $t) {
    my $r = {};
    @$r{@self_routes_cols} = map($_ eq '' ? undef : $_, split /\t/, $line);
    $r->{namespace} = $Init->{namespace};
    $r->{controller} = $Init->{controller};
    push @r, $r;
  }
  
  return @r;
}

sub auth_cookie {# action
  my $c = shift;
  my $json = $c->req->json;
  
  my ($cookie) = ($json && $json->{cookie})
    || $c->vars('cookie');
  
  unless ($cookie) {
    return $c->render(json=>{error=>"No cookie"})
      if $json;
    
    return $c->render(text=>"Error: no cookie");
    
  }
  
  my $profile = { %{$c->access->auth_cookie($c, $cookie) || {error=>"none profile by given cookie [$cookie]"}} };
  
  return $c->render(json=>{profile=>$profile})
    if $json;
  
  return $c->render(text=>"Success signed by cookie\n".$c->dumper($profile));
  
}

1;

=pod

=encoding utf8

=head1 Mojolicious::Plugin::RoutesAuthDBI::Admin

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 WARN

More or less complete! :)

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::Admin - is a Mojolicious::Controller for manage admin operations on DBI tables: namespaces, controllers, actions, routes, roles, users.

=head1 DB DESIGN DIAGRAM

See L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/blob/master/Diagram.svg>

=head1 SYNOPSIS

    $app->plugin('RoutesAuthDBI', 
        ...
        admin => {< hashref options list below >},
        ...
    );


=head2 OPTIONS

=head3 namespace

Namespace (string). Defaults to 'Mojolicious::Plugin::RoutesAuthDBI'.

=head3 controller

Module controller name. Defaults to 'Admin'.

Both above options determining the loadable module controller as concatenation C<namespace>::C<controller>.

=head3 prefix

String. Is a prefix for admin urls of this module. Default as name of controller to low case.

=head3 trust

String. Is a url subprefix for trust admin urls of this module. See defaults below.

=head3 role_admin

String. Is a name of role for admonistrators.

=head3 tables

Hashref of any DB tables names. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.

=head2 Default options

  admin = > {
    namespace => 'Mojolicious::Plugin::RoutesAuthDBI',
    controller => 'Admin',
    prefix => 'admin', # lc(<module>)
    trust => hmac_sha1_sum('admin', $app->secrets->[0]),
    role_admin => 'administrators',
  },

Examples options:

  admin = {}, # empty hashref sets defaults above
  
  admin => undef, # disable admin controller
  
  admin = > {prefix=>'myadmin', trust => 'foooobaaar'},# admin urls like: /myadmin/foooobaaar/



=head1 METHODS NEEDS IN PLUGIN

=head2 self_routes()

Builtin to this admin controller routes. Return array of hashrefs routes records for apply route on app. Depends on conf options I<prefix> and I<trust>.


=head1 ROUTES

There are number of app routes on this controller. See in console C< $perl your-app.pl routes >. That routes will not apply then admin controller disabled.

=head1 SEE ALSO

L<Mojolicious::Plugin::RoutesAuthDBI>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut