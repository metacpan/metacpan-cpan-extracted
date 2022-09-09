package PDK::DBI::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use DBIx::Custom;

#------------------------------------------------------------------------------
# 定义 PDK::DBI::Role 方法属性
#------------------------------------------------------------------------------
has dsn => (is => 'ro', isa => 'Str', required => 1,);

has user => (is => 'ro', isa => 'Str', required => 1,);

has password => (is => 'ro', isa => 'Str', required => 1,);

has option => (is => 'ro', isa => 'Undef|HashRef[Str]', default => undef,);

has dbi => (
  is      => 'ro',
  isa     => 'DBIx::Custom',
  lazy    => 1,
  builder => '_buildDbi',
  handles => qr/^(?:select|update|insert|delete|execute|user).*/,
);

#------------------------------------------------------------------------------
# _buildDbi 构建 DBIx::Custom 连接器
#------------------------------------------------------------------------------
sub _buildDbi {
  my $self  = shift;
  my %param = (dsn => $self->dsn, user => $self->user, password => $self->password);
  $param{option} = $self->option // {AutoCommit => 0, RaiseError => 1, PrintError => 0};

  if (defined $ENV{LANG}) {
    $ENV{NLS_CURRENCY}      = '*';
    $ENV{NLS_DUAL_CURRENCY} = '*';
  }
  my $dbi = DBIx::Custom->connect(%param);
  $dbi->quote('');
  return $dbi;
}

#------------------------------------------------------------------------------
# clone 克隆数据库连接
#------------------------------------------------------------------------------
sub clone {
  my $self  = shift;
  my $class = ref $self;
  return $class->new(dsn => $self->dsn, user => $self->user, password => $self->password, option => $self->option);
}

#------------------------------------------------------------------------------
# batchExecute 批量执行
#------------------------------------------------------------------------------
sub batchExecute {
  my ($self, $paramRef, $sqlString) = @_;
  my $num = 0;
  my $sth = $self->dbi->dbh->prepare($sqlString);
  for my $param (@{$paramRef}) {
    $sth->execute(@{$param});
    $self->dbi->dbh->commit if ++$num % 1000 == 0;
  }
}

#------------------------------------------------------------------------------
# disconnect 关闭数据库连接
#------------------------------------------------------------------------------
sub disconnect {
  my $self = shift;
  $self->dbi->dbh->disconnect;
}

#------------------------------------------------------------------------------
# reconnect 重连数据库
#------------------------------------------------------------------------------
sub reconnect {
  my $self = shift;
  $self->disconnect;
  $self->{dbi} = $self->_buildDbi;
}

#------------------------------------------------------------------------------
# batchInsert 批量插入 SQL
#------------------------------------------------------------------------------
sub batchInsert {
  my ($self, $columnMap, $tableName, $dataObjs) = @_;
  my ($attrWhichIsSingle, $attrWhichContainList, $attrTypes) = $self->parseColumnMap($columnMap);
  my @params;
  return if not defined $dataObjs;

  # 早期异常拦截
  confess "ERROR: dataObjs 参数不是一个hash的引用 也不是一个数组的引用" if ref($dataObjs) !~ /^(?:HASH|ARRAY)$/o;
  my @columnsSingle = keys %{$attrWhichIsSingle};
  my @attrsSingle   = values %{$attrWhichIsSingle};
  my @columnsList   = keys %{$attrWhichContainList};
  my @attrsList     = values %{$attrWhichContainList};
  my @columns       = (@columnsSingle, @columnsList);
  my @questionMarks = map {'?'} (0 .. $#columns);
  my $sqlString     = "insert into $tableName (" . join(',', @columns) . ") values (" . join(',', @questionMarks) . ")";

  # 从 5.012 values 可以处理数组与hash的引用
  for my $dataObj (values %{$dataObjs}) {
    my (@param, $column, $attr);
    for my $i (0 .. $#columnsSingle) {
      ($column, $attr) = ($columnsSingle[$i], $attrsSingle[$i]);
      $param[$i] = $dataObj->$attr;
    }
    if (not defined $attrTypes) {
      push(@params, \@param);
    }
    else {
      my ($attrMembers, $maxAttrMemberNums) = $self->getAttrMembers($attrTypes, $dataObj);
      for my $j (0 .. $maxAttrMemberNums - 1) {
        for my $k (0 .. $#columnsList) {
          $column                          = $columnsList[$k];
          $attr                            = $attrsList[$k];
          $param[$#columnsSingle + 1 + $k] = $attrMembers->{$attr}[$j];
        }
        push(@params, \@param);
      }
    }
  }
  $self->batchExecute(\@params, $sqlString);
}

#------------------------------------------------------------------------------
# getAttrMembers 获取属性成员对象
#------------------------------------------------------------------------------
sub getAttrMembers {
  my ($self, $attributes, $dataObj) = @_;
  my $result = {};
  my $min    = 0;
  my $max    = 0;

  for my $attribute (keys %{$attributes}) {
    my $flag = $attributes->{$attribute};
    if ($flag eq '@') {
      $result->{$attribute} = $dataObj->$attribute;
    }
    elsif ($flag eq '%k') {
      $result->{$attribute} = [keys %{$dataObj->$attribute}];
    }
    elsif ($flag eq '%v') {
      $result->{$attribute} = [values %{$dataObj->$attribute}];
    }
    my $length = scalar @{$result->{$attribute}};
    $max = $max > $length ? $max : $length;
    $min = $min < $length ? $min : $length;
  }
  return wantarray ? ($result, $max, $min) : $result;
}

#------------------------------------------------------------------------------
# parseColumnMap 解析数据库属性
#------------------------------------------------------------------------------
sub parseColumnMap {
  my ($self, $columnMap) = @_;
  my $attrWhichIsSingle    = {};
  my $attrWhichContainList = {};
  my $attrTypes;
  confess "ERROR: columnMap 参数不是一个数组的引用" if ref($columnMap) ne 'ARRAY';

  for my $columnInfo (@{$columnMap}) {
    my ($column, $attr, $attrType);
    if ($columnInfo =~ /^\s*(?<column>\w+)\s* => \s*(?<attr>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo) {
      $column   = $+{column};
      $attr     = $+{attr};
      $attrType = $+{attrType};
    }
    elsif ($columnInfo =~ /^\s*(?<column>\w+)\s*(?: \| \s* (?<attrType>\@|\%k|\%v) )?\s*$/xo) {
      $column   = $attr = $+{column};
      $attrType = $+{attrType};
    }
    else {
      confess "ERROR: columnMap 中的元素 $columnInfo 格式不符合要求";
    }

    if (defined $attrType) {
      $attrWhichContainList->{$column} = $attr;
      $attrTypes->{$attr}              = $attrType;
    }
    else {
      $attrWhichIsSingle->{$column} = $attr;
    }
  }
  return ($attrWhichIsSingle, $attrWhichContainList, $attrTypes);
}

#------------------------------------------------------------------------------
# 钩子函数 运行时检查
#------------------------------------------------------------------------------
for my $func (qw(execute delete update insert batchExecute)) {
  around $func => sub {
    my $orig = shift;
    my $self = shift;
    my $result;

    # 尝试提交数据，如果遇到异常则进行回退
    eval {
      $result = $self->$orig(@_);
      $self->dbi->dbh->commit;
    };

    if (!!$@) {
      if ($self->dbi->dbh->rollback) {
        confess "ERROR: $@";
      }
      else {
        confess "ERROR: $@\n" . $self->dbi->dbh->errstr;
      }
    }
    else {
      return $result;
    }
  };
}

1;
