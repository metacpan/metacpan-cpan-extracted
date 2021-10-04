package Netstack::DBI::Pg;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.018;
use Carp;
use Moose;
use namespace::autoclean;
use DBIx::Custom;

#------------------------------------------------------------------------------
# 继承 Netstack::DBI::Role 方法属性
#------------------------------------------------------------------------------
with 'Netstack::DBI::Role';

#------------------------------------------------------------------------------
# 定义 Netstack::DBI::Pg 方法属性
#------------------------------------------------------------------------------
has option => (
  is      => 'ro',
  isa     => 'Undef | HashRef[Str]',
  default => undef,
);

#------------------------------------------------------------------------------
# 追加 DBI 属性约束
#------------------------------------------------------------------------------
has '+dbi' => (
  isa => 'DBIx::Custom',
  # 代理 DBIx::Custom SQL 方法
  handles => qr/^(?:select|update|insert|delete|execute|user).*/,
);

# 钩子函数
for my $func (qw( execute delete update insert batchExecute )) {
  around $func => sub {
    my $orig = shift;
    my $self = shift;
    my $result;

    # 动态加载代码，如果执行异常则回滚
    eval {
      $result = $self->$orig(@_);
      $self->dbi->dbh->commit;
    };
    if ( length($@) ) {
      if ( $self->dbi->dbh->rollback ) {
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

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = ( @_ > 0 and ref( $_[0] ) eq 'HASH' ) ? $_[0]->%* : @_;
  if (  not defined $param{dsn}
    and defined $param{host}
    and defined $param{port}
    and defined $param{dbname} )
  {
    $param{dsn} = "dbi:Pg:dbname=$param{dbname};host=$param{host};port=$param{port}";
  }
  return $class->$orig(%param);
};

#------------------------------------------------------------------------------
# clone 克隆 Pg 对象实例
#------------------------------------------------------------------------------
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    dsn      => $self->dsn,
    user     => $self->user,
    password => $self->password,
    option   => $self->option
  );
}

#------------------------------------------------------------------------------
# clone 克隆 Pg 对象实例
#------------------------------------------------------------------------------
sub batchExecute {
  my $self = shift;
  $self->_rawExecute(@_);
}

#------------------------------------------------------------------------------
# _rawExecute 底层定义的执行方法 | 比multipleInsert略快，适合大批量或语句较复杂的操作
#------------------------------------------------------------------------------
sub _rawExecute {
  my ( $self, $paramRef, $sqlString ) = @_;
  my $num = 0;
  my $sth = $self->dbi->dbh->prepare($sqlString);
  for my $param ( @{$paramRef} ) {
    $sth->execute( @{$param} );
    $self->dbi->dbh->commit if ++$num % 5000 == 0;
  }
}

#------------------------------------------------------------------------------
# _buildDbi 构建 DBI 属性 | Role 要求必须实现的方法
#------------------------------------------------------------------------------
sub _buildDbi {
  my $self  = shift;
  my %param = (
    dsn      => $self->dsn,
    user     => $self->user,
    password => $self->password
  );
  $param{option} = $self->option // {
    AutoCommit => 0,
    RaiseError => 1,
    PrintError => 0
  };
  if ( defined $ENV{LANG} ) {
    $ENV{NLS_CURRENCY}      = '*';
    $ENV{NLS_DUAL_CURRENCY} = '*';
  }
  # 实例化 DBIx::Custom 对象
  my $dbi = DBIx::Custom->connect(%param);
  $dbi->quote('');
  # 返回 dbi 对象
  return $dbi;
}

#------------------------------------------------------------------------------
# disconnect 对象 SQL 会话
#------------------------------------------------------------------------------
sub disconnect {
  my $self = shift;
  $self->dbi->dbh->disconnect;
}

#------------------------------------------------------------------------------
# reconnect 先断开再连结新会话
#------------------------------------------------------------------------------
sub reconnect {
  my $self = shift;
  $self->disconnect;
  $self->{dbi} = $self->_buildDbi;
}

__PACKAGE__->meta->make_immutable;
1;
