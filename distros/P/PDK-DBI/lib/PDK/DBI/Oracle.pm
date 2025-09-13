package PDK::DBI::Oracle;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use DBIx::Custom;
use Carp;

# 数据库连接选项
# 默认值在 _buildDbi 中设置为 AutoCommit => 0, RaiseError => 1, PrintError => 0
has option => (
    is      => 'ro',
    isa     => 'Undef | HashRef[Str]',
    default => undef,
);

# 引入通用数据库操作角色
with 'PDK::DBI::Role';

# 使用 DBIx::Custom 作为 dbi 对象
# 并自动委托常用数据库方法
has '+dbi' => (
    isa     => 'DBIx::Custom',
    handles => qr/^(?:select|update|insert|delete|execute|user).*/,
);

# 包裹常用数据库操作方法，自动提交事务
# 如果出错则回滚，并抛出异常
for my $func (qw(execute delete update insert batchExecute)) {
    around $func => sub {
        my $orig = shift;
        my $self = shift;
        my $result;
        eval {
            $result = $self->$orig(@_);
            $self->dbi->dbh->commit; # 执行成功则提交
        };
        if ($@) {
            if ($self->dbi->dbh->rollback) {
                confess "ERROR: $@"; # 出错时回滚并抛异常
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

# 构造参数处理
# 如果未指定 dsn，但提供了 host, port, sid，则自动拼接 Oracle 的 DSN
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %param = (@_ > 0 and ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

    if (not defined $param{dsn} and defined $param{host} and defined $param{sid}) { 
        $param{port} //= '1521';
        $param{dsn} = "dbi:Oracle:host=$param{host};sid=$param{sid};port=$param{port}";
    }

    return $class->$orig(%param);
};

# 克隆当前数据库对象
sub clone {
    my $self = shift;
    return __PACKAGE__->new(
        dsn      => $self->dsn,
        user     => $self->user,
        password => $self->password,
        option   => $self->option
    );
}

# 批量执行 SQL，封装 _rawExecute
sub batchExecute {
    my $self = shift;
    $self->_rawExecute(@_);
}

# 低层批量执行方法
# 比 multipleInsert 更快，适合大批量或复杂 SQL
# 每 5000 条提交一次事务，避免事务过大
sub _rawExecute {
    my ($self, $paramRef, $sqlString) = @_;
    my $num = 0;
    my $sth = $self->dbi->dbh->prepare($sqlString);
    for my $param (@$paramRef) {
        $sth->execute(@$param);
        $self->dbi->dbh->commit if ++$num % 5000 == 0;
    }
}

# 构建 DBIx::Custom 对象
# 设置默认连接选项
# 当 LANG 环境变量存在时，设置 Oracle 风格的货币符号环境变量（兼容性处理）
sub _buildDbi {
    my $self = shift;
    my %param = (
        dsn      => $self->dsn,
        user     => $self->user,
        password => $self->password
    );
    $param{option} = $self->option // { AutoCommit => 0, RaiseError => 1, PrintError => 0 };

    if (defined $ENV{LANG}) {
        $ENV{NLS_CURRENCY} = '*';
        $ENV{NLS_DUAL_CURRENCY} = '*';
    }

    my $dbi = DBIx::Custom->connect(%param);
    $dbi->quote('');
    return $dbi;
}

# 断开数据库连接
sub disconnect {
    my $self = shift;
    $self->dbi->dbh->disconnect;
}

# 重建数据库连接
sub reconnect {
    my $self = shift;
    $self->disconnect;
    $self->{dbi} = $self->_buildDbi;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

PDK::DBI::Oracle - Oracle 数据库操作工具类

=head1 SYNOPSIS

    use PDK::DBI::Oracle;

    my $db = PDK::DBI::Oracle->new(
        host     => '127.0.0.1',
        port     => 1521,
        sid      => 'ORCL',
        user     => 'scott',
        password => 'tiger',
    );

    # 执行查询
    my $rows = $db->select(
        table  => 'EMP',
        column => ['EMPNO', 'ENAME']
    )->all;

    # 插入数据（自动提交）
    eval {
        $db->insert(
            table  => 'EMP',
            param  => { EMPNO => 9999, ENAME => 'TEST' }
        );
    };
    if ($@) {
        warn "数据库操作失败: $@";
    }

=head1 DESCRIPTION

该模块基于 L<DBIx::Custom>，对 Oracle 数据库提供了更高层次的封装。
支持事务自动提交/回滚、批量执行、自动构建 DSN 等功能。

=head1 ATTRIBUTES

=over 4

=item host

字符串类型，Oracle 服务器主机名。

=item port

字符串或整数类型，Oracle 监听端口，默认 1521。

=item sid

字符串类型，Oracle 数据库实例名。

=item dsn

数据库 DSN。若未显式指定，将由 C<host>、C<port>、C<sid> 自动拼接。

=item user

字符串类型，数据库用户名。

=item password

字符串类型，数据库密码。

=item option

哈希引用，数据库连接选项。
默认值为：

    {
        AutoCommit => 0,
        RaiseError => 1,
        PrintError => 0
    }

=back

=head1 METHODS

=head2 select / insert / update / delete / execute

继承自 L<DBIx::Custom> 的常用数据库操作方法。

=head2 batchExecute(\@params, $sql)

批量执行 SQL 语句，内部调用 L</_rawExecute>。
每 5000 条自动提交一次事务，适合大批量数据处理。

=head2 _rawExecute(\@params, $sql)

底层批量执行方法。
逐条执行 C<@params> 中的参数绑定 SQL，支持自动分批提交。

=head2 clone

克隆当前数据库对象，生成新的连接实例。

=head2 disconnect

断开当前数据库连接。

=head2 reconnect

重建数据库连接。

=head1 ERROR HANDLING

=over 4

=item *

所有事务型方法（insert、update、delete、execute、batchExecute）出错时会自动回滚，并通过 C<Carp::confess> 抛出异常。

=item *

rollback 失败时，会额外输出 DBI 错误信息。

=back

=head1 DSN CONSTRUCTION

若未显式指定 C<dsn>，则根据以下规则自动拼接：

    dbi:Oracle:host=$host;sid=$sid;port=$port

=head1 COMPATIBILITY

当环境变量 C<LANG> 存在时，会设置以下 Oracle 环境变量以提高兼容性：

    NLS_CURRENCY       = '*'
    NLS_DUAL_CURRENCY  = '*'

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
