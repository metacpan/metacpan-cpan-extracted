package Mojolicious::Command::generate::DBIxCustomModel;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(class_to_file class_to_path getopt encode decode decamelize);
use Mojo::File 'path';
use Data::Dumper;

has description => 'generate DBIx::Custom model directory structure';
has usage => sub{shift->extract_usage};
has package => "MyApp";
has lib => "lib";
has config => sub{
  {
    base   => {
      sdel  => "is_deleted",
      ctime => "create_time",
      mtime => "update_time"
    },
    models => {
    
    }
  }
};

sub run{
  my ($self, @args) = @_;
  my $app = $self->app;
  my $home = $app->home;
  getopt \@args, 'p|package=s' => \my $package, 'l|lib=s' => \my $lib, 'c|config=s' => \my $config;
  $self->package($package) if($package);
  $self->lib($lib) if($lib);
  print "package : " . $self->package . $/;
  print "lib : " . $self->lib . $/;
  print "home : " . $home . $/;
  if($config){
    print "==========  start load config  ==========" . $/;
    my $file = $home->child($config);
    print "config file : " . $file . $/;
    $self->config($self->load($file, $app)) if(-e $file);
    print "==========  end load config  ==========" . $/;
  }
  
  my $base_model = {
    package      => $self->package . "::Model",
    base_package => "Mojolicious::DBIxCustom::Model"
  };
  
  $base_model = { %{$base_model}, %{$self->config->{base}} } if($self->config->{base});
  
  $self->render_to_file("baseModel", $home->child($self->lib, class_to_path($base_model->{package})), $base_model);
  
  my $dbi = $app->dbi;
  my $tables = $dbi->execute("SHOW TABLE STATUS;")->all;
  
  foreach my $table (@{$tables}){
    $table = { %{$self->config->{models}->{$table->{Name}}}, %{$table} } if($self->config->{models} && $self->config->{models}->{$table->{Name}});
    my $ctime = $table->{ctime} || "";
    my $base_ctime = $base_model->{ctime} || "";
    my $mtime = $table->{mtime} || "";
    my $base_mtime = $base_model->{mtime} || "";
    my $sdel = $table->{sdel} || "";
    my $base_sdel = $base_model->{sdel} || "";
    $table->{Comment} = encode("utf8", $table->{Comment}) if($table->{Comment});
    $table->{columns} = $dbi->execute("show full columns from $table->{Name};")->all;
    foreach my $col (@{$table->{columns}}){
      $col->{Comment} = encode("utf8", $col->{Comment}) if($col->{Comment});
      $col->{Default} = encode("utf8", $col->{Default}) if($col->{Default});
      if($col->{Key} eq "PRI"){
        $table->{primary_key} = [] unless($table->{primary_key});
        push(@{$table->{primary_key}}, $col);
      }
      if($ctime eq $col->{Field}){
        $ctime = "";
      }
      if($mtime eq $col->{Field}){
        $mtime = "";
      }
      if($sdel eq $col->{Field}){
        $sdel = "";
      }
      
      if($base_ctime eq $col->{Field}){
        $base_ctime = "";
      }
      if($base_mtime eq $col->{Field}){
        $base_mtime = "";
      }
      if($base_sdel eq $col->{Field}){
        $base_sdel = "";
      }
    }
    
    if($table->{ctime} && $ctime eq $table->{ctime}){
      $table->{ctime} = undef;
    }
    if($table->{mtime} && $mtime eq $table->{mtime}){
      $table->{mtime} = undef;
    }
    if($table->{sdel} && $sdel eq $table->{sdel}){
      $table->{sdel} = undef;
    }
    
    $table->{overwrite_fields} = [];
    if(!$table->{ctime} && $base_model->{ctime} && $base_ctime eq $base_model->{ctime}){
      push(@{$table->{overwrite_fields}}, "ctime");
    }
    if(!$table->{mtime} && $base_model->{mtime} && $base_mtime eq $base_model->{mtime}){
      push(@{$table->{overwrite_fields}}, "mtime");
    }
    if(!$table->{sdel} && $base_model->{sdel} && $base_sdel eq $base_model->{sdel}){
      push(@{$table->{overwrite_fields}}, "sdel");
    }
    
    $table->{package} = $base_model->{package} . "::$table->{Name}";
    $table->{base_package} = $base_model->{package};
    $self->render_to_file("model", $home->child($self->lib, class_to_path($table->{package})), $table);
  }
  
}



sub load{$_[0]->parse(decode('UTF-8', path($_[1])->slurp), @_[1, 2, 3])}

sub parse{
  my ($self, $content, $file, $app) = @_;
  
  # Run Perl code in sandbox
  my $config = eval 'package Mojolicious::Command::generate::DBIxCustomModel::Sandbox; no warnings;'
    . "sub app; local *app = sub { \$app }; use Mojo::Base -strict; $content";
  die qq{Can't load StatusCode configuration from file "$file": $@} if($@);
  die qq{StatusCode Configuration file "$file" did not return a hash reference.\n}
    unless(ref $config eq 'HASH');
  
  return $config;
}


=encoding utf8


=head1 NAME

Mojolicious::Command::generate::DBIxCustomModel - generate DBIx::Custom model directory structure

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';


=head1 SYNOPSIS

    Usage: APPLICATION generate DBIxCustomModel [OPTIONS]
 
      mojo generate DBIxCustomModel -p MyApp -l lib -c generate_model.conf
      mojo generate DBIxCustomModel --package MyApp --lib lib --conf generate_model.conf
 
    Options:
      -h, --help   Show this summary of available options
      -p, --package the package of generate model on ,defaults "MyApp"
      -l, --lib   lib path ,defaults "lib"
      -c, --config  config file
      
    Config: content of config fiel
      {
        base   => { # base mode config
          sdel  => "is_deleted", # sremove field
          ctime => "create_time",# create time field
          mtime => "update_time",# update time field
          code=> '   # user defiend code
            sub abc{
            }
          '
        },
        models => { # the key is table name
          table_name=>{ # table model config
            sdel  => "is_deleted", # sremove field
            ctime => "create_time",# create time field
            mtime => "update_time",# update time field
            code=> ' # user defiend code
              sub abc{
              }
            '
          }
        }
      }

      
=head1 Config

可以在配置文件中进行以下配置：

  {
    base   => { # 对 base_package 的配置
      sdel  => "is_deleted", # 软删除字段
      ctime => "create_time",# 创建时间字段
      mtime => "update_time",# 更新时间字段
      code=> '   # 用户自定义扩展代码
        sub abc{
        }
      '
    },
    models => { # 以表名为key，对各个表的配置
      table_name=>{ # 对 base_package 的配置
        sdel  => "is_deleted", # 软删除字段
        ctime => "create_time",# 创建时间字段
        mtime => "update_time",# 更新时间字段
        code=> ' # 用户自定义扩展代码
          sub abc{
          }
        '
      }
    }
  }


=head1 AUTHOR

WFSO, C<< <461663376@qq.com> >>

=cut

1; # End of Mojolicious::Command::generate::DBIxCustomModel


__DATA__

@@ baseModel
% my $model = shift;
package <%= $model->{package} %>;
use strict;
use warnings;
use <%= $model->{base_package} %> -base;
use utf8;

% # 生成 sdel 属性
% if($model->{sdel}){
has sdel => '<%= $model->{sdel} %>';
%}

% # 生成 ctime 属性
% if($model->{ctime}){
has ctime => '<%= $model->{ctime} %>';
% }

% # 生成 mtime 属性
% if($model->{mtime}){
has mtime => '<%= $model->{mtime} %>';
%}

% # 生成 自定义代码 code
%if($model->{code}){
%= $model->{code}
%}

1;

@@ model

% my $table = shift;
package <%= $table->{package} %>;
use strict;
use warnings;
use <%= $table->{base_package} %> -base;
use utf8;

% # 生成 columns 属性
%if(@{$table->{columns}}){
has columns => sub{
  [
  %foreach my $col (@{$table->{columns}}){
    %if($col == $table->{columns}->[-1]){
    '<%= $col->{Field} %>' # <%= $col->{Type} %> <%= $col->{Default} ? ',Default:'.$col->{Default} : '' %>; <%= $col->{Comment} %>
    %}else{
    '<%= $col->{Field} %>', # <%= $col->{Type} %> <%= $col->{Default} ? ',Default:'.$col->{Default} : '' %>; <%= $col->{Comment} %>
    %}
  %}
  ]
};
%}

% # 生成 primary_key 属性
%if($table->{primary_key} && @{$table->{primary_key}}){
  %if($table->{Auto_increment} && @{$table->{primary_key}} == 1){
    % my $pk = $table->{primary_key}->[0];
has primary_key => '<%= $pk->{Field} %>'; # <%= $pk->{Type} %> <%= $pk->{Default} ? ',Default:'.$pk->{Default} : '' %>; <%= $pk->{Comment} %>
  %}else{
has primary_key => sub{
  [
  %foreach my $col (@{$table->{primary_key}}){
    %if($col == $table->{primary_key}->[-1]){
    '<%= $col->{Field} %>' # <%= $col->{Type} %> <%= $col->{Default} ? ',Default:'.$col->{Default} : '' %>; <%= $col->{Comment} %>
    %}else{
    '<%= $col->{Field} %>', # <%= $col->{Type} %> <%= $col->{Default} ? ',Default:'.$col->{Default} : '' %>; <%= $col->{Comment} %>
    %}
  %}
  ]
};
  %}
%}

% # 生成 sdel 属性
%if($table->{sdel}){
has sdel => '<%= $table->{sdel} %>';
%}

% # 生成 ctime 属性
%if($table->{ctime}){
has ctime => '<%= $table->{ctime} %>';
%}

% # 生成 mtime 属性
%if($table->{mtime}){
has mtime => '<%= $table->{mtime} %>';
%}

% # 生成需要 overwrite 的属性
%if($table->{Comment} ne "VIEW" && $table->{overwrite_fields} && @{$table->{overwrite_fields}}){
%my $last = $table->{overwrite_fields}->[-1];
has [qw/<%foreach(@{$table->{overwrite_fields}}){%><%= $_ %><%= $_ eq $last ? '':' ' %><%}%>/];
%}

% # 生成 自定义代码 code
%if($table->{code}){
%= $table->{code}
%}


%# 生成 注释
%if($table->{Comment} eq "VIEW"){
=head1 view <%= $table->{Name}.$/ %>
view name: <%= $table->{Name}.$/ %>
=cut
%}else{
=head1 table <%= $table->{Name}.$/ %>
  %if($table->{Comment}){
<%= $table->{Comment}.$/ %>
  %}else{
table name: <%= $table->{Name}.$/ %>
  %}
=cut
%}


1;

