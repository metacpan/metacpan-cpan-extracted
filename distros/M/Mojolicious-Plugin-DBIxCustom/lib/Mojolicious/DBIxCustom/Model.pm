package Mojolicious::DBIxCustom::Model;
use strict;
use warnings;
use DBIx::Custom::Model -base;
use utf8;
use Carp qw/confess cluck/;

has 'sdel';


sub last_id{
  my $self = shift;
  my $dbi = $self->dbi;
  confess "extension DBIx::Custom and implement [last_id] method please" unless($dbi->can("last_id"));
  return $dbi->last_id(@_);
}


## 添加
## 返回值为 hashref
## rows 影响了多少行
## 表名 ,param执行过滤后的待写入对象
## object ,写入成功后，查询得到的数据对象
## param ,参数原样返回
sub create{
  my $self = shift;
  my $param = shift;
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($param->{$sdel})){
    $param->{$sdel} = 0;
  }
  
  ## 过滤param ，保证只有表中有的字段才会出现在insert语句中
  my $mapper = $self->dbi->mapper(param => $param, pass => $self->columns);
  my $obj = $mapper->map;
  my $rows = $self->insert($obj);
  my $pk = $self->primary_key;
  
  ## 表的主键只有一个，且primary_key属性为字符串时 说明主键是自增的
  ## 其他情况，如primary_key属性为arrayref时，主键不是自增的
  my $object;
  unless(ref $pk){
    $param->{$pk} = $obj->{$pk} = $self->last_id($obj) unless(defined $param->{$pk});
    $object = $self->get_by_id($obj->{$pk});
    $object = $object->{$self->name} if($object && $object->{$self->name});
  }else{
    my @pa = ();
    for(@{$pk}){
      push(@pa, $obj->{$_});
    }
    $object = $self->get_by_id(@pa);
    $object = $object->{$self->name} if($object && $object->{$self->name});
  }
  return {rows => $rows, $self->name => $obj, object => $object, param => $param};
}

## 修改
## 返回值为 hashref
## rows 影响了多少行
## 表名 ,param执行过滤后的待更新对象
## list , update语句修改的数据对象，修改前的值
## object ,update语句修改的数据对象中的第一个，修改前的值
## param ,参数原样返回
## where ,执行update时的where条件 hashref
sub edit{
  my $self = shift;
  my $param = shift;
  my $where = shift;
  my $pk = $self->primary_key;
  my $have_pk = 1;
  my %w = ();
  
  ## 如果param中有主键信息存在，则把param中的主键合并到where中
  ## 为了保证被修改的字段中不包含主键，需要把主键从param中删除
  if(ref $pk){
    for(@{$pk}){
      $have_pk &&= exists($param->{$_});
      $w{$_} = delete $param->{$_} if(exists($param->{$_}));
    }
  }else{
    $have_pk &&= exists($param->{$pk});
    $w{$pk} = delete $param->{$pk} if(exists($param->{$pk}));
  }
  unless($where || $have_pk){
    cluck("required [where] parameter");
    return undef;
  }
  
  ## 合并where条件
  $where ||= {};
  $where = {%w, %{$where}};
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  ## 过滤param中的字段，保证只有表中有的字段才会出现在update语句中
  my $mapper = $self->dbi->mapper(param => $param, pass => $self->columns);
  $mapper->condition('exists');
  my $obj = $mapper->map;
  
  
  ## 查询得到修改前的结果
  my $list = $self->select(where => $where)->all;
  
  ## 执行修改操作
  my $rows = $self->update($obj, where => $where);
  
  ## 把主键还原给param 和obj,方便service层使用
  if(ref $pk){
    for(@{$pk}){
      if(exists($where->{$_})){
        $obj->{$_} = $where->{$_};
        $param->{$_} = $where->{$_};
      }
    }
  }else{
    if(exists($where->{$pk})){
      $obj->{$pk} = $where->{$pk};
      $param->{$pk} = $where->{$pk};
    }
  }
  
  return {
    rows        => $rows,
    $self->name => $obj,
    param       => $param,
    object      => $list->[0],
    list        => $list,
    where       => $where
  };
}

## 硬删除
## 根据参数 构造 where 条件
## 支持 hash ，以and形式组成各个键
## 支持 id 的列表
## 支持 id 的数组引用
## 返回值为 hashref
## rows 影响了多少行
## list , delete语句删除的数据对象，删除前的值
## object ,delete语句删除的数据对象中的第一个，删除前的值
## where ,执行delete时的where条件
sub remove{
  my $self = shift;
  my $where = shift;
  
  ## 根据参数 构造 where 条件
  if(defined $where && !ref $where){
    ## 参数为id列表时的解析
    my $pk = $self->primary_key;
    if(ref $pk){
      if(@{$pk} == 1){
        $where = {$pk->[0] => $where};
      }else{
        unshift(@_, $where);
        if(@{$pk} <= @_){
          $where = {};
          for(@{$pk}){
            $where->{$_} = shift;
          }
        }
      }
    }else{
      $where = {$pk => $where};
    }
  }elsif(ref $where eq "ARRAY"){
    ## 参数为id 的数组引用时的解析
    my $pk = $self->primary_key;
    my @ids = @{$where};
    if(@{$pk} <= @ids){
      $where = {};
      for(@{$pk}){
        $where->{$_} = shift(@ids);
      }
    }
  }
  
  ## 如果where不是一个hash则给出提示
  if(ref $where ne "HASH"){
    cluck("[where] parameter required a hashref");
    return undef;
  }
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  ## 查询需要出将要删除的内容
  my $list = $self->select(where => $where)->all;
  
  ## 执行删除
  my $rows = $self->delete(where => $where);
  return {rows => $rows, list => $list, object => $list->[0], where => $where};
}


## 硬删除
## 根据参数 构造 where 条件
## 支持 id 的列表
## 支持 id 的数组引用
## 返回值为 hashref
## rows 影响了多少行
## object ,delete语句删除的数据对象，删除前的值
## where ,执行delete时的where条件
sub remove_by_id{
  my $self = shift;
  
  ## 获取参数
  my $t = ref $_[0] ? shift : undef;
  my @ids = $t ? @{$t} : @_;
  
  ## 构造where 条件
  my $pk = $self->primary_key;
  my $where = {};
  if(ref $pk eq "ARRAY" && @ids >= @{$pk}){
    for(@{$pk}){
      $where->{$_} = shift(@ids);
    }
  }elsif(ref $pk eq "ARRAY"){
    cluck("parameter number is insufficient");
  }else{
    $where->{$pk} = shift(@ids);
  }
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  ## 查询需要出将要删除的内容
  my $object = $self->select(where => $where)->one;
  
  ## 执行删除
  my $rows = $self->delete(where => $where);
  return {rows => $rows, object => $object, where => $where};
}


## 软删除
## 根据参数 构造 where 条件
## 支持 hash ，以and形式组成各个键
## 支持 id 的列表
## 支持 id 的数组引用
## 返回值为 hashref
## rows 影响了多少行
## list , update语句删除的数据对象，删除前的值
## object ,update语句删除的数据对象中的第一个，删除前的值
## where ,执行update时的where条件
sub sremove{
  my $self = shift;
  my $where = shift;
  
  ## 根据参数 构造 where 条件
  
  if(defined $where && !ref $where){
    ## 参数为id列表时的解析
    my $pk = $self->primary_key;
    if(ref $pk){
      if(@{$pk} == 1){
        $where = {$pk->[0] => $where};
      }else{
        unshift(@_, $where);
        if(@{$pk} <= @_){
          $where = {};
          for(@{$pk}){
            $where->{$_} = shift;
          }
        }
      }
    }else{
      $where = {$pk => $where};
    }
  }elsif(ref $where eq "ARRAY"){
    ## 参数为id 的数组引用时的解析
    my $pk = $self->primary_key;
    my @ids = @{$where};
    if(@{$pk} <= @ids){
      $where = {};
      for(@{$pk}){
        $where->{$_} = shift(@ids);
      }
    }
  }
  
  my $flag = shift || 1;
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  if($sdel){
    ## 查询需要出将要删除的内容
    my $list = $self->select(where => $where)->all;
    
    ## 执行软删除操作
    my $rows = $self->update({$sdel => $flag}, where => $where);
    return {rows => $rows, list => $list, object => $list->[0], where => $where};
  }else{
    cluck "dont support sremove";
  }
}


## 软删除
## 根据参数 构造 where 条件
## 支持 id 的列表
## 支持 id 的数组引用
## 返回值为 hashref
## rows 影响了多少行
## object ,update语句删除的数据对象，删除前的值
## where ,执行update时的where条件
sub sremove_by_id{
  my $self = shift;
  
  
  ## 获取参数
  my $t = ref $_[0] ? shift : undef;
  my @ids = $t ? @{$t} : @_;
  
  ## 构造where 条件
  my $pk = $self->primary_key;
  my $where = {};
  if(ref $pk eq "ARRAY" && @ids >= @{$pk}){
    for(@{$pk}){
      $where->{$_} = shift(@ids);
    }
  }elsif(ref $pk eq "ARRAY"){
    cluck("parameter number is insufficient");
  }else{
    $where->{$pk} = shift(@ids);
  }
  
  my $flag = $t ? shift : shift(@ids);
  $flag ||= 1;
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  if($sdel){
    ## 查询需要出将要删除的内容
    my $object = $self->select(where => $where)->one;
    
    ## 执行软件删除
    my $rows = $self->update({$sdel => $flag}, where => $where);
    return {rows => $rows, object => $object, where => $where};
  }else{
    cluck "dont support sremove";
  }
}

## 允许的参数类型如下：
## 1. 要查询的字段：arrayref (可选，默认查询表中所有字段)
## 2. 主键的值：arrayref or array (必选)
## 返回值为 hashref
## rows 影响了多少行
## 表名  查询得到的数据对象
## object ,查询得到的数据对象
## where ,执行select时的where条件
sub get_by_id{
  my $self = shift;
  
  ## 获取参数，构造fields 和 ids
  my ($fields, $ids);
  if(ref $_[0]){
    $fields = shift;
    if(@_ > 0){
      $ids = ref $_[0] ? shift : [@_];
    }
  }else{
    $ids = [@_];
  }
  unless($ids){
    $ids = $fields;
    $fields = undef;
  }
  
  ## 构造where条件
  my $pk = $self->primary_key;
  my $where = {};
  if(ref $pk && @{$pk} <= @{$ids}){
    for(@{$pk}){
      $where->{$_} = shift(@{$ids});
    }
  }elsif(ref $pk){
    cluck "parameter number is insufficient";
  }else{
    $where->{$pk} = shift(@{$ids});
  }
  
  ## 添加软删除标记
  my $sdel = $self->sdel;
  if($sdel && !exists($where->{$sdel})){
    $where->{$sdel} = 0;
  }
  
  ## 执行查询操作
  if(defined $ids){
    my $obj = $self->select($fields ? $fields : (), where => $where)->one;
    return {$self->name => $obj, object => $obj, where => $where};
  }
  return undef;
}


sub AUTOLOAD{
  my $self = shift;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  
  ## --------参数支持--------
  ## columns 可选
  ## field 值 必选
  ## 后面可以跟其他select方法可接收的参数，如：append等
  ## --------返回值为 hashref--------
  ## rows 查到了多少行
  ## 表名  查询得到的数据对象的第一条
  ## object ,查询得到的数据对象的第一条
  ## list , 查询得到的数据对象的列表
  ## where ,执行select时的where条件
  if($method =~ /^get_by_(.+)$/){
    my $wk = $1;
    my ($columns);
    if(ref $_[0]){
      $columns = shift;
    }
    my $where = {$wk => shift};
    
    ## 添加软删除标记
    my $sdel = $self->sdel;
    if($sdel && !exists($where->{$sdel})){
      $where->{$sdel} = 0;
    }
    
    my $list = $self->select($columns ? $columns : (), where => $where, @_)->all;
    return {
      rows        => scalar(@{$list}),
      $self->name => $list->[0],
      object      => $list->[0],
      list        => $list,
      where       => $where
    };
  }
  
  
  ## --------参数支持--------
  ## columns 可选
  ## field 值 必选
  ## 后面可以跟其他select方法可接收的参数，如：append等
  ## --------返回值为 整数--------
  ## 共计多少行
  if($method =~ /^count_by_(.+)$/){
    my $wk = $1;
    my ($columns);
    if(ref $_[0]){
      $columns = shift;
    }
    my $where = {$wk => shift};
    
    ## 添加软删除标记
    my $sdel = $self->sdel;
    if($sdel && !exists($where->{$sdel})){
      $where->{$sdel} = 0;
    }
    
    return $self->count($columns ? $columns : (), where => $where, @_);
  }
  
  ## 与remove 方法的返回值格式相同
  ## 返回值为 hashref
  ## rows 影响了多少行
  ## list , delete语句删除的数据对象，删除前的值
  ## object ,delete语句删除的数据对象中的第一个，删除前的值
  ## where ,执行delete时的where条件
  if($method =~ /^remove_by_(.+)$/){
    my $wk = $1;
    my $where = {$wk => shift};
    return $self->remove($where);
  }
  
  ## 与sremove 方法的返回值格式相同
  ## 返回值为 hashref
  ## rows 影响了多少行
  ## list , update语句删除的数据对象，删除前的值
  ## object ,update语句删除的数据对象中的第一个，删除前的值
  ## where ,执行update时的where条件
  if($method =~ /^sremove_by_(.+)$/){
    my $wk = $1;
    my $where = {$wk => shift};
    return $self->sremove($where);
  }
  
  confess qq{Can't locate obj method "$method" via package "$package"}
}


1;