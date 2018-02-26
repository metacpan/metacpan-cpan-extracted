package Mojolicious::Services;
use Mojo::Base 'Mojolicious::Service';
use Carp 'croak';
use Mojo::Loader qw/find_modules load_class/;
use Mojo::Util qw/camelize decamelize/;
use Scalar::Util;

our $VERSION = '2.1.0';

has services => sub{{}};
has namespaces => sub{["Mojolicious::Service"]};
has lazy => 1;


sub load_service{
  my ($self, $name) = @_;
  
  # Try all namespaces and full module name
  my $suffix = $name =~ /^[a-z0-9]/ ? camelize $name : $name;
  my @classes = map {"${_}::$suffix"} @{$self->namespaces};
  for my $class (@classes, $name){
    if(_load($class)){
      my $service = $class->new(models => $self->models, dbi => $self->dbi, app => $self->app, parent => $self);
      Scalar::Util::weaken $service->{app};
      Scalar::Util::weaken $service->{models};
      Scalar::Util::weaken $service->{dbi};
      Scalar::Util::weaken $service->{parent};
      $self->service($name, $service);
      return $service;
    }
  }
  
  # Not found
  die qq{Service "$name" missing, maybe you need to install it?\n};
}

sub load_all_service{
  my $self = shift;
  foreach(map{find_modules($_)}@{$self->namespaces}){
    $_ =~ /^.+\:([^\:]+)$/;
    my $name = decamelize($1);
    if(_load($_)){
      my $service = $_->new(models => $self->models, dbi => $self->dbi, app => $self->app, parent => $self);
      Scalar::Util::weaken $service->{app};
      Scalar::Util::weaken $service->{models};
      Scalar::Util::weaken $service->{dbi};
      Scalar::Util::weaken $service->{parent};
      $self->service($name, $service);
    }
  }
}

sub new{
  my ($self, $conf) = @_;
  my $namespaces = delete $conf->{namespaces} if($conf->{namespaces});
  $self = $self->SUPER::new($conf);
  if($namespaces && ref $namespaces eq "ARRAY"){
    unshift(@{$self->namespaces}, $_) for(reverse @{$namespaces});
  }
  $self->load_all_service unless($self->lazy);
  return $self;
}

sub service{
  my ($self, $name, $service) = @_;
  
  # Set service
  if($service){
    $self->services->{$name} = $service;
    return $self;
  }
  
  unless($self->services->{$name}){
    $self->load_service($name);
  }
  
  # Check services existence
  croak qq{service "$name" is not yet created } unless($self->services->{$name});
  
  # Get service
  return $self->services->{$name};
}



sub _load{
  my $module = shift;
  return $module->isa('Mojolicious::Service') unless(my $e = load_class $module);
  ref $e ? die $e : return undef;
}


=encoding utf8

=head1 NAME

Mojolicious::Services - Mojolicious::Services 是为Mojolicious框架提供的Service管理插件。

=head1 SYNOPSIS

    use Mojolicious::services
    my $service_manage = Mojolicious::services->new({
          dbi=>DBIx::Custom->new(),
          models=>{},
          namespaces=>s["Mojolicious::Service"],
          lazy => 1
      });
      
    ## fetch a service
    my $user_service = $service_manage->service("user");



=head1 DESCRIPTION

Mojolicious::services是为Mojolicious框架提供Service支持的模块。


=head1 ATTRIBUTES

Mojolicious::services 从 Mojolicious::Service中继承了所有属性，并实现以下属性。


=head2 services

存储service的属性。


=head2 namespaces

namespaces 用于说明service类所在的命名空间，这个属性的值是一个arrayref 类型的值，支持在多个命名空间中查找service。


=head2 lazy

用于说明是否启用懒加载模式。
如果值为true则启用懒加载，只有在实际请求一个service时才加载其类并实例化一个service对象。
如果为flase则在创建Mojolicious::services时加载所有service类并实例化成对象。


=head1 METHODS

Mojolicious::services 从 Mojolicious::Service中继承了所有方法，并实现以下方法。

=head2 load_service

根据service的名字加载service。



=head2 load_all_service

加载 namespaces 属性指定的所有命名空间下的所有service，并实例化。
注：只有在非懒加载模式的初始化阶段才会调用这个方法。



=head2 new

生成一个新的Mojolicious::services对象。


=head2 service

根据 service 的名称从 services 属性中获取 service。如果在 services 属性中不存在对应的键，则尝试从 namespaces 属性指定的命名空间中加载并实例化一个service。如果尝试加载后仍获取失败，则返回 undef。



=head1 AUTHOR

wfso, C<< <461663376@qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-services at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-services>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::services


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-services>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-services>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-services>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-services/>

=back


=cut

1; # End of Mojolicious::services
