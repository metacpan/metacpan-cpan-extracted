package Mojolicious::Plugin::Service;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw/load_class/;
use Scalar::Util;


sub register{
  my ($self, $app, $conf) = @_;
  
  # Merge config
  $conf = {%{$conf},%{$app->config->{service_config}}} if($app->config->{service_config});
  $conf->{app} = $app;
  if($app->renderer->get_helper("dbi")){
    $conf->{dbi} ||= $app->dbi;
    if($app->dbi->can("models")){
      $conf->{models} ||= $app->dbi->models;
    }
  }
  
  if($app->renderer->get_helper("models")){
    $conf->{models} ||= $app->models;
  }
  
  my $services_class = delete $conf->{services_class} || 'Mojolicious::Services';
    
  my $e = load_class($services_class);
  if($e){
    ref $e ? die $e:die "can't fond the module named '$services_class' ,inspect your installed please";
    return undef;
  }elsif($services_class->isa("Mojolicious::Services")){
    my $services = $services_class->new($conf);
    Scalar::Util::weaken $services->{app};
    Scalar::Util::weaken $services->{dbi};
    Scalar::Util::weaken $services->{models};
    $app->helper(service=>sub{
        my ($c,$name) = @_;
        return $services->service($name);;
      }
    );
  }else{
    $app->log->fatal("services_class named '$services_class' is not a subclass for Mojolicious::Services ");
    die "services_class named '$services_class' is not a subclass for Mojolicious::Services ";
  }
  
}


=encoding utf8

=head1 NAME

Mojolicious::Plugin::Service - 向Mojolicious框架中引入Service管理器的插件!


=head1 DESCRIPTION

向Mojolicious框架中引入Service管理器的插件。


=head1 SYNOPSIS


    # Mojolicious
    $app->plugin('Service',$config);
 
    # Mojolicious::Lite
    plugin('DefaultHelpers',$config);



=head1 METHODS

Mojolicious::Plugin::Service inherits all methods from Mojolicious::Plugin and implements the following new ones.

=head2 register

    $plugin->register(Mojolicious->new,$config);
    
Register helper in Mojolicious application named service.


=head1 config Option

register 方法中除接受Mojolicious对象为参数外，还接受一个config参数。这个config参数是必须是一个hashref。

    {
        dbi=>DBIx::Custom->new(),
        models=>DBIx::Custom->new->models,
        namespaces=>s["Mojolicious::Service"],
        services_class=>"T::Services",
        lazy => 1
    }
    

=head2 dbi

dbi 是为service提供数据库操作接口的对象。


=head2 models

models 是为service提供数据模型操作接口的对象。


=head2 namespace

namespace 用于说明service类所在的命名空间，这个属性的值是一个arrayref 类型的值，支持在多个命名空间中查找service。


=head2 lazy

用于说明是否启用懒加载模式。
如果值为true则启用懒加载，只有在实际请求一个service时才加载其类并实例化一个service对象。
如果为flase则在创建Mojolicious::Services时加载所有service类并实例化成对象。

=head2 services_class

用户自己实现一个Mojolicious::Services的子类。作为插件中的service管理器对象。



=head1 AUTHOR

wfso, C<< <461663376@qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-Services at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Services>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Service


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Services>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Services>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Services>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Services/>

=back


=cut

1; # End of Mojolicious::Plugin::Service
