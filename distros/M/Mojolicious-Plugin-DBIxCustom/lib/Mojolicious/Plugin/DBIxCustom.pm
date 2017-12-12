package Mojolicious::Plugin::DBIxCustom;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw/load_class/;

our $VERSION = '0.1.1';


sub register {
  my ($self, $app, $conf) = @_;
  $conf = {%{$conf},%{$app->config->{dbi_config}}} if($app->config->{dbi_config});
  my $dbi_class = delete $conf->{dbi_class} || 'DBIx::Custom';
  my $model_namespace = delete $conf->{model_namespace} if($conf->{model_namespace});
  
  my $dbi;
  my $e = load_class($dbi_class);
  if($e){
    ref $e ? die $e:die "can't fond the module named '$dbi_class' ,inspect your installed please";
    return undef;
  }elsif($dbi_class->isa("DBIx::Custom")){
    $dbi = $dbi_class->new($conf);
    $dbi->include_model($model_namespace) if($model_namespace);
    $app->helper(dbi=>sub{$dbi->connect});
    $app->helper(model=>sub{
        my ($c,$model_name) = @_;
        return $dbi->connect->model($model_name);
      }
    );
  }else{
    $app->log->fatal("dbi_class named '$dbi_class' is not a subclass for DBIx::Custom ");
    die "dbi_class named '$dbi_class' is not a subclass for DBIx::Custom";
  }
}


=encoding utf8

=head1 NAME

Mojolicious::Plugin::DBIxCustom - 链接DBIx::Custom到Mojolicious的插件

=head1 VERSION

Version 0.1.0


=head1 SYNOPSIS


    # Mojolicious
    $self->plugin('DBIxCustom',{
        dsn=>"DBI:SQLite:dbname=:memory:",
        connector=>1,## 默认使用DBIx::Connector
        model_namespace=>"T::Model",
        dbi_class=>"T::MyDBIxCustom"
    });
 
    # Mojolicious::Lite
    plugin 'DBIxCustom',{
        dsn=>"DBI:SQLite:dbname=:memory:",
        connector=>1,## 默认使用DBIx::Connector
        model_namespace=>"T::Model",
        dbi_class=>"T::MyDBIxCustom"
    };


=head1 METHODS

Mojolicious::Plugin::DBIxCustom 覆盖了Mojolicious::Plugin中的register方法。

=head2 register

向Mojolicious中添加了两具helper：dbi和model。
其中dbi默认是一个DBIx::Custom对象，你也可以通过指定dbi_class来指定一个DBIx::Custom的子类，用来实例化为dbi。
名为model的helper是dbi中model方法的别名。

=head1 OPTION

这里的OPTION介绍的是register方法的参数支持的OPTION。

=head2 DBIx::Custom初始化参数

所有用于DBIx::Custom初始化参数都可以通过register的option来指定。
如：dsn、user、password、connector、option等。

=head2 dbi_class

dbi_class 默认为DBIx::Custom你也可以自己指定，但必须为DBIx::Custom的子类，它会被实例化得到dbi对象。


=head2 model_namespace

model_namespace是用于作为参数来调用dbi_class的include_model方法的。调用此方法时会自动加载对应命名空间下的所有model。

    $dbi->include_model($model_namespace);
    
如果没有给出此参数，则不会调用include_model方法。


=head1 AUTHOR

wfso, C<< <461663376 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-dbixcustom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-DBIxCustom>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::DBIxCustom


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-DBIxCustom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-DBIxCustom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-DBIxCustom>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-DBIxCustom/>

=back


=head1 ACKNOWLEDGEMENTS




=cut

1; # End of Mojolicious::Plugin::DBIxCustom
