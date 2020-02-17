package Mojolicious::Plugin::Crud;
use Mojo::Base 'Mojolicious::Plugin';

use Lingua::EN::Inflect qw/PL/;
use Mojo::Util qw( camelize );

#------------------------------------------------------------------------------
#   Crud 版本信息
#------------------------------------------------------------------------------
our $VERSION = '0.0.10';

#------------------------------------------------------------------------------
#   Crud 插件注册方法
#------------------------------------------------------------------------------
sub register {
  my ( $self, $app ) = @_;

  # 注册 routes 快捷指令，接收定制属性
  $app->routes->add_shortcut(
    api_routes => sub {
      # 继承 $route
      my $r      = shift;
      my $params = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };

      # 提取参数
      my $name       = $params->{name} or die "Parameter 'name' missing";
      my $readonly   = $params->{readonly} || 0;
      my $controller = $params->{controller} || $name;

      # 转换为 controller 格式
      $controller = camelize($controller);

      # 生成复数类型路由，并转换为小写 URI
      my $route_part = $params->{route} || PL( $name, 10 );
      $route_part = lc($route_part);
      $app->log->info("Creating Routes for resource '$name' (controller => $controller)");

      # 生成路由后丢给控制器
      my $resource = $r->route("/$route_part")->to( "controller" => $controller );

      #------------------------------------------------------
      # 接收 GET 请求，对应前端数据查询请求
      #------------------------------------------------------
      $resource->get->to('#get')->name("get_$route_part");
      $app->log->debug( " GET " . $r->to_string . "/$route_part  (api_get)" );

      # 后端路由是否只读
      if ( !$readonly ) {
        #------------------------------------------------------
        # 接收 POST 请求，对应前端新增数据请求
        #------------------------------------------------------
        $resource->post->to('#create')->name("create_$name");
        $app->log->debug( " POST " . $r->to_string . "/$route_part  (api_create)" );

        #------------------------------------------------------
        # 接收 DELETE 请求，对应前端删除数据请求
        #------------------------------------------------------
        $resource->delete->to('#delete')->name("delete_$name");
        $app->log->debug( " DELETE " . $r->to_string . "/$route_part/  (api_delete)" );

        #------------------------------------------------------
        # 接收 PUT 请求，对应前端更新数据请求
        #------------------------------------------------------
        $resource->put->to('#update')->name("update_$name");
        $app->log->debug( " PUT " . $r->to_string . "/$route_part/  (api_update)" );
      }

      # 检测是否为 download 路由
      $resource = $r->under(
        "/$route_part/download" => sub {
          my $c = shift;
          $c->app->log->debug("Download: resource /$route_part/download");
          return 1;
        }
      )->to( controller => $controller );

      #------------------------------------------------------
      # 接收 GET 请求，处理 download 表单下载
      #------------------------------------------------------
      $resource->get->to("#download")->name("download_$name");
      $app->log->debug( " GET " . $r->to_string . "/$route_part/download  (api_download)" );

      # 返回 CRUD + Download 样式路由
      return $resource;
    }
  );
}

1;

=head1 NAME

Mojolicious::Plugin::RESTRoutes - routing helper for RESTful operations

=head1 VERSION

version 0.0.10

=head1 DESCRIPTION

This Mojolicious plugin adds a routing helper for
L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete>
operations via HTTP to the app.

The routes are intended, but not restricted to be used by AJAX applications.

=head1 MOJOLICIOUS SHORTCUTS

=head2 api_routes

Can be used to easily generate the needed RESTful routes for a resource.

    my $r = $self->routes;
    my $userroute = $r->api_routes(name => 'user');

    # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
    #    GET /users                      --> My::Mojo::User::rest_list()
    #   POST /users                      --> My::Mojo::User::rest_create()
    #    GET /users/:userid              --> My::Mojo::User::rest_show()
    #    PUT /users/:userid              --> My::Mojo::User::rest_update()
    # DELETE /users/:userid              --> My::Mojo::User::rest_remove()

I<Please note>: the english plural form of the given C<name> attribute will be
used in the route, i.e. "users" instead of "user". If you want to specify
another string, see parameter C<route> below.

You can also chain C<api_routes>:

    $userroute->api_routes(name => 'hat', readonly => 1);

    # Installs the following additional routes:
    #    GET /users/:userid/hats         --> My::Mojo::Hat::rest_list()
    #    GET /users/:userid/hats/:hatid  --> My::Mojo::Hat::rest_show()

The target controller has to implement the following methods:

=over 4

=item *

C<rest_list>

=item *

C<rest_create>

=item *

C<rest_show>

=item *

C<rest_update>

=item *

C<rest_remove>

=back

B<Parameters to control the route creation>

=over

=item name

The name of the resource, e.g. a "user", a "book" etc. This name will be used to
build the route URL as well as the controller name (see example above).

=item readonly (optional)

If set to 1, no create/update/delete routes will be created

=item controller (optional)

Default behaviour is to use the resource name to build the CamelCase controller
name (this is done by L<Mojolicious::Routes::Route>). You can change this by
directly specifying the controller's name via the I<controller> attribute.

Note that you have to give the real controller class name (i.e. CamelCased or
whatever you class name looks like) including the full namespace.

    $r->api_routes(name => 'user', controller => 'My::Mojo::Person');

    # Installs the following routes:
    #    GET /users         --> My::Mojo::Person::rest_list()
    #    ...

=item route (optional)

Specify a name for the route, i.e. prevent automatic usage of english plural
form of the C<name> parameter as the route component.

    $r->api_routes(name => 'angst', route => 'aengste');

    # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
    #    GET /aengste       --> My::Mojo::Angst::rest_list()

=back

B<How to retrieve the parameters / IDs>

There are two ways to retrieve the IDs given by the client in your C<rest_show>,
C<rest_update> and C<rest_remove> methods.

Example request: C<GET /users/5/hats/no9>

1. New way: the stash entry C<fm.ids> holds a hash with all ids:

    package My::Mojo::Hats;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show {
        use Data::Dump qw(dump);
        print dump($self->stash('fm.ids'));

        # { user => 5, hat => 'no9' }
    }

2. Old way: for each resource there will be a parameter C<***id>, e.g.:

    package My::Mojo::Hat;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show {
        my ($self) = @_;
        my $user = $self->param('userid');
        my $hat = $self->param('hatid');
        return $self->render(text => "$userid, $hatid");

        # text: "5, no9"
    }

Furthermore, the parameter C<idname> holds the name of the last ID in the route:

    package My::Mojo::Hat;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show   {
        my $p_name = $self->param('idname');
        my $id = $self->param($p_name);
        return $self->render(text => sprintf("%s = %s", $p_name, $id || ''));

        # text: "hatid = 5"
    }

=head1 METHODS

=head2 register

Adds the routing helper (called by Mojolicious).

=encoding utf8

=head1 AUTHOR


WENWU YAN, C<< <careline at 126.com> >>


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by WENWU YAN.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
