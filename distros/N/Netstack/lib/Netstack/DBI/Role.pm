package Netstack::DBI::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义 Netstack::DBI::Role 方法属性
#------------------------------------------------------------------------------
has dsn => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has user => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has password => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has dbi => (
  is      => 'ro',
  lazy    => 1,
  builder => '_buildDbi',
);

#------------------------------------------------------------------------------
# 继续 Netstack::DBI::Role 必须实现的方法
#------------------------------------------------------------------------------
requires 'clone';
requires 'batchExecute';

#------------------------------------------------------------------------------
# getAttrMembers 获取成员对象
#------------------------------------------------------------------------------
sub getAttrMembers {
  my ( $self, $attrTypes, $dataObj ) = @_;
  # 初始化对象
  my $attrMembers = {};
  my ( $min, $max ) = ( 0, 0 );
  for my $attr ( keys $attrTypes->%* ) {
    my $attrType = $attrTypes->{$attr};
    if ( $attrType eq '@' ) {
      $attrMembers->{$attr} = $dataObj->$attr;
    }
    elsif ( $attrType eq '%k' ) {
      $attrMembers->{$attr} = [ keys $dataObj->$attr->%* ];
    }
    elsif ( $attrType eq '%v' ) {
      $attrMembers->{$attr} = [ values $dataObj->$attr->%* ];
    }
    # 修正 max min
    my $length = scalar $attrMembers->{$attr}->@*;
    $max = $max > $length ? $max : $length;
    $min = $min < $length ? $min : $length;
  }
  return wantarray ? ( $attrMembers, $max, $min ) : $attrMembers;
}

#------------------------------------------------------------------------------
# parseColumnMap 解析数据库字段对象
#------------------------------------------------------------------------------
sub parseColumnMap {
  my ( $self, $columnMap ) = @_;
  # 异常拦截，入参对象必须为数组引用
  confess "ERROR: columnMap 参数不是一个数组的引用" if ref $columnMap ne 'ARRAY';
  # 初始化对象
  my $attrWhichIsSingle    = {};
  my $attrWhichContainList = {};

  # 遍历属性数组
  my $attrTypes;
  for my $columnInfo ( $columnMap->@* ) {
    my ( $column, $attr, $attrType );
    if ( $columnInfo =~ /^\s*(?<column>\w+)\s* => \s*(?<attr>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo ) {
      ( $column, $attr, $attrType ) = ( $+{column}, $+{attr}, $+{attrType} );
    }
    elsif ( $columnInfo =~ /^\s*(?<column>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo ) {
      $column   = $attr = $+{column};
      $attrType = $+{attrType};
    }
    else {
      confess "ERROR: columnMap 中的元素 $columnInfo 格式不符合要求";
    }
    if ( defined $attrType ) {
      $attrWhichContainList->{$column} = $attr;
      $attrTypes->{$attr}              = $attrType;
    }
    else {
      $attrWhichIsSingle->{$column} = $attr;
    }
  }
  # 返回计算结果
  return ( $attrWhichIsSingle, $attrWhichContainList, $attrTypes );
}

#------------------------------------------------------------------------------
# batchInsert 批量插入数据库对象
#------------------------------------------------------------------------------
sub batchInsert {
  my ( $self, $columnMap, $tableName, $dataObjs ) = @_;
  # 异常拦截，必须定义 $dataObjs
  return if not defined $dataObjs;
  # 入参约束，必须为哈希引用或数组引用
  confess "ERROR: dataObjs 必须是哈希引用或数组引用" if ref $dataObjs !~ /^(?:HASH|ARRAY)$/io;

  # 解析出更新属性字段
  my ( $attrWhichIsSingle, $attrWhichContainList, $attrTypes ) = $self->parseColumnMap($columnMap);
  my @params;
  my @columnsSingle = keys $attrWhichIsSingle->%*;
  my @attrsSingle   = values $attrWhichIsSingle->%*;
  my @columnsList   = keys $attrWhichContainList->%*;
  my @attrsList     = values $attrWhichContainList->%*;
  my @columns       = ( @columnsSingle, @columnsList );
  my @questionMarks = map {'?'} ( 0 .. $#columns );
  my $sqlString = "insert into $tableName (" . join( ',', @columns ) . ") values (" . join( ',', @questionMarks ) . ")";

  for my $dataObj ( values %{$dataObjs} ) {

    #从 5.012 values 可以处理数组与hash的引用
    my @param;
    my ( $column, $attr );
    for my $i ( 0 .. $#columnsSingle ) {
      ( $column, $attr ) = ( $columnsSingle[$i], $attrsSingle[$i] );
      $param[$i] = $dataObj->$attr;
    }
    if ( not defined $attrTypes ) {
      push( @params, \@param );
    }
    else {
      my ( $attrMembers, $maxAttrMemberNums ) = $self->getAttrMembers( $attrTypes, $dataObj );
      for my $j ( 0 .. $maxAttrMemberNums - 1 ) {
        for my $k ( 0 .. $#columnsList ) {
          $column                            = $columnsList[$k];
          $attr                              = $attrsList[$k];
          $param[ $#columnsSingle + 1 + $k ] = $attrMembers->{$attr}[$j];
        }
        push( @params, \@param );
      }
    }
  }
  $self->batchExecute( \@params, $sqlString );
}

1;
