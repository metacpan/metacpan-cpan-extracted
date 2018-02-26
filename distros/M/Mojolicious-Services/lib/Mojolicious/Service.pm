package Mojolicious::Service;
use Mojo::Base -base;
use Carp qw/cluck confess/;

has [qw/dbi models app c dmn parent/];

sub model{
  my ($self, $name) = @_;
  
  # Check model existence
  cluck qq{model "$name" is not yet created } unless($self->models && $self->models->{$name});
  
  # Get model
  return $self->models->{$name};
}

sub service{
  my $self = shift;
  return $self->parent->service(@_) if($self->parent);
  confess "require [parent] field";
}

## 调用 model 层的 create 方法
sub mcreate{
  my $self = shift;
  my $table = $self->dmn;
  my $model = $self->model($table);
  my $obj = $model->create(@_);
  return undef unless($obj && $obj->{object});
  return $obj->{object};
}

## 调用 model 层的 edit 方法
sub medit{
  my $self = shift;
  my $table = $self->dmn;
  my $model = $self->model($table);
  my $obj = $model->edit(@_);
  return undef unless($obj && $obj->{rows});
  return $obj->{rows};
}

## 调用 model 层的 remove 方法
sub mremove{
  my $self = shift;
  my $table = $self->dmn;
  my $model = $self->model($table);
  my $obj = $model->remove(@_);
  return undef unless($obj && $obj->{rows});
  return $obj->{rows};
}

## 调用 model 层的 sremove 方法
sub msremove{
  my $self = shift;
  my $table = $self->dmn;
  my $model = $self->model($table);
  my $obj = $model->sremove(@_);
  return undef unless($obj && $obj->{rows});
  return $obj->{rows};
}


## 调用 model 层的 count 方法
sub mcount{
  my $self = shift;
  my $table = $self->dmn;
  my $model = $self->model($table);
  return $model->count(@_);
}



sub AUTOLOAD{
  my $self = shift;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  no strict qw/refs/;
  
  ## 在哪个包里调用的这个方法
  my $pkg = caller(0);
  
  ## 调用 model 层的create方法
  if($method =~ /^mcreate_(.+)$/){
    my $table = $1;
    my $model = $self->model($table);
    my $obj = $model->create(@_);
    return undef unless($obj && $obj->{object});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{object};
  }
  
  
  ## 调用 model 层的edit方法
  if($method =~ /^medit_(.+)$/){
    my $table = $1;
    my $model = $self->model($table);
    my $obj = $model->edit(@_);
    return undef unless($obj && $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  
  ## 调用 model 层的remove方法
  if($method =~ /^mremove_(.+)$/){
    my $table = $1;
    my $model = $self->model($table);
    my $obj = $model->remove(@_);
    return undef unless($obj && $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  
  ## 调用 model 层的sremove方法
  if($method =~ /^msremove_(.+)$/){
    my $table = $1;
    my $model = $self->model($table);
    my $obj = $model->sremove(@_);
    return undef unless($obj && $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  ## 调用 model 层的 count 方法
  if($method =~ /^mcount_(.+)$/){
    my $table = $1;
    my $model = $self->model($table);
    return $model->count(@_);
  }
  
  ## get_by_字段名
  if($method =~ /^get_by_(.+)$/){
    my $table = $self->dmn;
    my $field = $1;
    my $mmethod = "get_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && $obj->{$model->name});
    return $pkg->isa(__PACKAGE__) ? $obj : $field eq "id" ? $obj->{$model->name} : $obj->{list};
  }
  
  ## get_表名_by_字段名
  if($method =~ /^get_(.+)_by_(.+)$/){
    my $table = $1;
    my $field = $2;
    my $mmethod = "get_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && $obj->{$model->name});
    return $pkg->isa(__PACKAGE__) ? $obj : $field eq "id" ? $obj->{$model->name} : $obj->{list};
  }
  
  
  ## remove_by_字段名
  if($method =~ /^remove_by_(.+)$/){
    my $table = $self->dmn;
    my $field = $1;
    my $mmethod = "remove_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && defined $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  ## remove_表名_by_字段名
  if($method =~ /^remove_(.+)_by_(.+)$/){
    my $table = $1;
    my $field = $2;
    my $mmethod = "remove_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && defined $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  
  
  ## sremove_表名_by_字段名
  if($method =~ /^sremove_by_(.+)$/){
    my $table = $self->dmn;
    my $field = $1;
    my $mmethod = "sremove_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && defined $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  ## sremove_表名_by_字段名
  if($method =~ /^sremove_(.+)_by_(.+)$/){
    my $table = $1;
    my $field = $2;
    my $mmethod = "sremove_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    my $obj = $model->$mmethod(@_);
    return undef unless($obj && defined $obj->{rows});
    return $pkg->isa(__PACKAGE__) ? $obj : $obj->{rows};
  }
  
  
  ## count_表名_by_字段名
  if($method =~ /^count_by_(.+)$/){
    my $table = $self->dmn;
    my $field = $2;
    my $mmethod = "count_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    return $model->$mmethod(@_);
  }
  
  
  ## count_表名_by_字段名
  if($method =~ /^count_(.+)_by_(.+)$/){
    my $table = $1;
    my $field = $2;
    my $mmethod = "count_by_" . $field;
    my $model = $self->model($table);
    cluck "the model [$table] if not found!" unless($model);
    
    return $model->$mmethod(@_);
  }
  
  confess qq{Can't locate object method "$method" via package "$package"}
}


=encoding utf8


=head1 NAME

Mojolicious::Service - Mojolicious框架中所有Service的基类（具体的Service需要用户实现）!


=head1 SYNOPSIS

    use Mojolicious::Service
    my $service = Mojolicious::Service->new({
          dbi=>DBIx::Custom->new(),
          models=>{}
      });
      
    my $user->some_mothed(arg1,arg2,……);


=head1 DESCRIPTION

Mojolicious框架中所有Service的基类（具体的Service需要用户实现）!

=head1 ATTRIBUTES

=head2 dbi

dbi 是为service提供数据库操作接口的对象。


=head2 models

models 是为service提供数据模型操作接口的对象。


=head2 app

当前应用程序的引用，通常是Mojolicious对象。

=head2 c

当前控制器的引用，通常是Mojolicious::Controller子类的对象。


=head1 METHODS

=head2 model

根据model的名称从 models 属性中获取model。


=head1 AUTHOR

wfso, C<< <461663376@qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-Services at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Services>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Service


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

1; # End of Mojolicious::Service
