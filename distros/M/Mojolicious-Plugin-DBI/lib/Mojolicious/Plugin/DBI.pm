package Mojolicious::Plugin::DBI;
use Mojo::Base 'Mojolicious::Plugin';

#   加载 DBIx-Custom
use DBIx::Custom;

#------------------------------------------------------------------------------
#   Mojo DBI 版本信息
#------------------------------------------------------------------------------
our $VERSION = '0.0.1';

#------------------------------------------------------------------------------
#   Mojo DBI 插件入口, $conf 用来接收变量
#------------------------------------------------------------------------------
sub register {
  my ( $self, $app, $conf ) = @_;

  #   提取 DSN 配置参数
  my $dsn      = $conf->{"dsn"} or die ": Parameter 'dsn' missing";
  my $username = $conf->{"username"};
  my $password = $conf->{"password"};
  my $options  = $conf->{"options"};

  $app->log->debug($username);
  $app->log->debug($password);
  $app->log->debug($dsn);
  #   尝试 连接 数据库
  my $connect = DBIx::Custom->connect( $dsn, $username, $password, $options );
  $connect->quote('');

  #   注册别名，可在控制器、App和模板内调用
  my $short_name = $conf->{"helper"} || "dbi";
  $app->helper(
    $short_name => sub {
      my $self = shift;
      return $connect;
    }
  );
}

1;

