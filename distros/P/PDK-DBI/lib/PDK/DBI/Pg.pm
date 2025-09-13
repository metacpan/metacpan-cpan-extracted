package PDK::DBI::Pg;

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

# 引入通用数据库角色
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
# 如果未指定 dsn，但提供了 host, port, dbname，则自动拼接 PostgreSQL 的 DSN
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %param = (@_ > 0 and ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

    if (not defined $param{dsn} and defined $param{host} and defined $param{dbname}) {
        $param{port} //= '5432';
        $param{dsn} = "dbi:Pg:dbname=$param{dbname};host=$param{host};port=$param{port}";
    }

    return $class->$orig(%param);
};

# 克隆当前数据库对象
sub clone {
    my $self = shift;
    return __PACKAGE__->new(dsn => $self->dsn, user => $self->user, password => $self->password, option => $self->option);
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

PDK::DBI::Pg - PostgreSQL 数据库操作类

=head1 SYNOPSIS

    use PDK::DBI::Pg;

    my $db = PDK::DBI::Pg->new(
        host     => '127.0.0.1',
        port     => 5432,
        dbname   => 'testdb',
        user     => 'postgres',
        password => 'secret',
    );

    # 单条插入
    $db->insert('users', { name => 'alice', age => 20 });

    # 查询
    my $rows = $db->select(table => 'users')->all;

    # 批量插入
    my $params = [
        [1, 'bob'],
        [2, 'charlie'],
    ];
    $db->batchExecute($params, 'insert into users(id, name) values (?, ?)');

=head1 DESCRIPTION

该模块基于 L<DBIx::Custom> 封装，继承 L<PDK::DBI::Role>，
提供了 PostgreSQL 数据库的连接、批量执行、事务管理等功能。

对常见的 C<insert>、C<update>、C<delete>、C<execute> 方法进行了事务封装，
执行成功后自动提交，出错时自动回滚并抛出异常。

=head1 ATTRIBUTES

=over 4

=item dsn

数据库连接字符串，例如：

    dbi:Pg:dbname=test;host=localhost;port=5432

=item user

数据库用户名。

=item password

数据库密码。

=item host

主机名。如果未提供 dsn，可以通过 host/port/dbname 自动拼接。

=item port

端口号，默认 5432。

=item dbname

数据库名。

=item option

哈希引用，数据库连接选项。
默认值为：

    {
        AutoCommit => 0,
        RaiseError => 1,
        PrintError => 0,
    }

=item dbi

C<DBIx::Custom> 对象。
提供 C<select>、C<update>、C<insert>、C<delete>、C<execute> 等方法的委托调用。

=back

=head1 METHODS

=head2 clone()

克隆当前数据库对象，复制其连接参数，返回新对象。

=head2 batchExecute(\@params, $sql)

批量执行 SQL 语句。
内部调用 C<_rawExecute>，适合大批量插入或复杂 SQL 的执行。

=head2 _rawExecute(\@params, $sql)

低层批量执行方法。
每 5000 条数据提交一次事务，以减少大事务对性能和内存的影响。

=head2 disconnect()

断开数据库连接。

=head2 reconnect()

重新建立数据库连接。
等价于先执行 C<disconnect>，再调用内部的 C<_buildDbi>。

=head2 _buildDbi()

内部方法，用于构建 C<DBIx::Custom> 对象。
会根据配置生成数据库连接，并应用默认或用户自定义的选项。

=head1 ERROR HANDLING

=over 4

=item *

所有数据库操作均在事务中执行，出错时会自动回滚。

=item *

执行失败时，会抛出 L<Carp::confess> 异常，并包含错误信息。

=back

=head1 EXAMPLES

    use PDK::DBI::Pg;

    my $db = PDK::DBI::Pg->new(
        host     => '127.0.0.1',
        port     => 5432,
        dbname   => 'testdb',
        user     => 'postgres',
        password => 'secret',
    );

    eval {
        $db->insert('users', { name => 'alice', age => 20 });
    };
    if ($@) {
        warn "数据库操作失败: $@";
    }

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
