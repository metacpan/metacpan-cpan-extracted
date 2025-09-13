package PDK::DBI::Mysql;

use utf8;
use v5.30;
use Moose;
use DBIx::Custom;
use namespace::autoclean;
use Carp qw(croak);

# 数据库连接选项
# 默认值在 _buildDbi 中设置为 AutoCommit => 0, RaiseError => 1, PrintError => 0
has option => (
    is      => 'ro',
    isa     => 'Maybe[HashRef[Str]]',
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
# 出错时回滚并抛出异常
for my $func (qw(execute delete update insert batchExecute)) {
    around $func => sub {
        my ($orig, $self, @args) = @_;
        my $result;
        eval {
            $result = $self->$orig(@args);
            $self->dbi->dbh->commit; # 执行成功提交事务
        };
        if (!!$@) {
            my $error = $@;
            eval {$self->dbi->dbh->rollback}; # 出错回滚
            croak "提交事务异常: $error" . ($@ ? "\n回滚失败: " . $self->dbi->dbh->errstr : "");
        }
        return $result;
    };
}

# 构造参数处理
# 如果未指定 dsn，但提供 host 和 dbname，则自动拼接 MySQL 的 DSN
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my %param = @args == 1 && ref $args[0] eq 'HASH' ? %{$args[0]} : @args;

    if (not defined $param{dsn} and defined $param{host} and defined $param{dbname}) {
        $param{port} //= '3306';
        $param{dsn} = "DBI:mysql:database=$param{dbname};host=$param{host};port=$param{port}";
    }

    return $class->$orig(%param);
};

# 克隆当前数据库对象
sub clone {
    my $self = shift;
    return __PACKAGE__->new(
        map {$_ => $self->$_} qw(dsn user password option)
    );
}

# 批量执行 SQL，封装 _rawExecute
sub batchExecute {
    my ($self, $params, $sql) = @_;
    $self->_rawExecute($params, $sql);
}

# 低层批量执行方法
# 每 5000 条提交一次事务，适合大批量或复杂 SQL
sub _rawExecute {
    my ($self, $params, $sql) = @_;
    my $sth = $self->dbi->dbh->prepare($sql);
    my $count = 0;
    for my $param (@$params) {
        $sth->execute(@$param);
        $self->dbi->dbh->commit if ++$count % 5000 == 0;
    }
    $self->dbi->dbh->commit if $count % 5000 != 0; # 提交剩余未提交的事务
}

# 构建 DBIx::Custom 对象
# 设置默认连接选项
# 并对 MySQL 的标识符使用反引号
sub _buildDbi {
    my $self = shift;
    my %param = (
        dsn      => $self->dsn,
        user     => $self->user,
        password => $self->password,
        option   => $self->option // { AutoCommit => 0, RaiseError => 1, PrintError => 0 },
    );

    # 兼容性处理：当 LANG 环境存在时，设置 Oracle 风格货币符号
    if ($ENV{LANG}) {
        $ENV{NLS_CURRENCY} = '*';
        $ENV{NLS_DUAL_CURRENCY} = '*';
    }

    my $dbi = DBIx::Custom->connect(%param);
    $dbi->quote('`'); # MySQL 标识符使用反引号
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

PDK::DBI::Mysql - MySQL 数据库操作类

=head1 SYNOPSIS

    use PDK::DBI::Mysql;

    my $db = PDK::DBI::Mysql->new(
        host     => '127.0.0.1',
        port     => 3306,
        dbname   => 'testdb',
        user     => 'root',
        password => 'secret',
    );

    # 插入数据
    $db->insert('users', { name => 'alice', age => 20 });

    # 查询数据
    my $rows = $db->select(table => 'users')->all;

    # 批量插入
    my $params = [
        [1, 'bob'],
        [2, 'charlie'],
    ];
    $db->batchExecute($params, 'INSERT INTO users(id, name) VALUES (?, ?)');

=head1 DESCRIPTION

该模块基于 L<DBIx::Custom> 封装，继承 L<PDK::DBI::Role>，
提供了 MySQL 数据库的连接、批量执行、事务管理等功能。

对常见的 C<insert>、C<update>、C<delete>、C<execute> 方法进行了事务封装，
执行成功后会自动提交，出错时自动回滚并抛出异常。

=head1 ATTRIBUTES

=over 4

=item dsn

数据库连接字符串，例如：

    DBI:mysql:database=test;host=localhost;port=3306

=item user

数据库用户名。

=item password

数据库密码。

=item host

主机名。如果未提供 dsn，可以通过 host/port/dbname 自动拼接。

=item port

端口号，默认 3306。

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
每 5000 条数据提交一次事务，循环结束后会提交剩余未提交的记录。

=head2 disconnect()

断开数据库连接。

=head2 reconnect()

重新建立数据库连接。
等价于先执行 C<disconnect>，再调用内部的 C<_buildDbi>。

=head2 _buildDbi()

内部方法，用于构建 C<DBIx::Custom> 对象。
会根据配置生成数据库连接，并应用默认或用户自定义的选项。
在 MySQL 下，标识符会使用反引号进行引用。

=head1 ERROR HANDLING

=over 4

=item *

所有数据库操作均在事务中执行，出错时会自动回滚。

=item *

执行失败时，会抛出 L<Carp::croak> 异常，并包含错误信息。

=back

=head1 EXAMPLES

    use PDK::DBI::Mysql;

    my $db = PDK::DBI::Mysql->new(
        host     => '127.0.0.1',
        dbname   => 'testdb',
        user     => 'root',
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
