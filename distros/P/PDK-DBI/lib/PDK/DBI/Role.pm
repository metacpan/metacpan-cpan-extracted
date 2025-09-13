package PDK::DBI::Role;

use utf8;
use v5.30;
use Moose::Role;
use Carp;

# 数据库连接字符串（必填）
has dsn => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# 数据库用户名（必填）
has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# 数据库密码（必填）
has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# DBI 对象，延迟构建
has dbi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_buildDbi',
);

# 要求实现的接口方法
requires 'clone';
requires 'batchExecute';

#----------------------------------------------------------------------
# getAttrMembers
# 根据属性类型获取对象成员
#   @  - 数组引用
#   %k - 哈希的键
#   %v - 哈希的值
# 返回：
#   标量上下文：属性成员哈希
#   列表上下文：(属性成员哈希, 最大长度, 最小长度)
#----------------------------------------------------------------------
sub getAttrMembers {
    my ($self, $attrTypes, $dataObj) = @_;
    my $attrMembers = {};
    my ($min, $max) = (0, 0);
    for my $attr (keys %$attrTypes) {
        my $attrType = $attrTypes->{$attr};
        if ($attrType eq '@') {
            $attrMembers->{$attr} = $dataObj->$attr;
        }
        elsif ($attrType eq '%k') {
            $attrMembers->{$attr} = [ keys %{$dataObj->$attr} ];
        }
        elsif ($attrType eq '%v') {
            $attrMembers->{$attr} = [ values %{$dataObj->$attr} ];
        }
        my $length = scalar(@{$attrMembers->{$attr}});
        $max = $max > $length ? $max : $length;
        $min = $min < $length ? $min : $length;
    }
    return (wantarray ? ($attrMembers, $max, $min) : $attrMembers);
}

#----------------------------------------------------------------------
# parseColumnMap
# 解析列与对象属性的映射关系
# 支持的 columnMap 格式：
#   "column => attr | 类型"
#   "column | 类型"
#   "column"
# 类型：
#   @  - 数组引用
#   %k - 哈希键
#   %v - 哈希值
# 返回：
#   (单值属性映射, 列表属性映射, 属性类型)
#----------------------------------------------------------------------
sub parseColumnMap {
    my ($self, $columnMap) = @_;
    my $attrWhichIsSingle = {};
    my $attrWhichContainList = {};
    my $attrTypes;

    confess("错误: columnMap 参数不是一个数组引用") if ref($columnMap) ne 'ARRAY';

    for my $columnInfo (@$columnMap) {
        my ($column, $attr, $attrType);
        if ($columnInfo =~ /^\s*
                             (?<column>\w+)
                             \s* => \s*
                             (?<attr>\w+)
                             \s*
                             (?: \| \s* (?<attrType>\@|\%k|\%v) )?
                             \s*$/xo) {
            ($column, $attr, $attrType) = ($+{column}, $+{attr}, $+{attrType});
        }
        elsif ($columnInfo =~ /^\s*
                             (?<column>\w+)
                             \s*
                             (?: \| \s* (?<attrType>\@|\%k|\%v) )?
                             \s*$/xo) {
            $column = $attr = $+{column};
            $attrType = $+{attrType};
        }
        else {
            confess("错误: columnMap 中的元素 $columnInfo 格式不符合要求");
        }

        if (defined $attrType) {
            $attrWhichContainList->{$column} = $attr;
            $attrTypes->{$attr} = $attrType;
        }
        else {
            $attrWhichIsSingle->{$column} = $attr;
        }
    }

    return ($attrWhichIsSingle, $attrWhichContainList, $attrTypes);
}

#----------------------------------------------------------------------
# batchInsert
# 批量插入数据
# 参数：
#   $columnMap  - 列与属性的映射关系
#   $tableName  - 表名
#   $dataObjs   - 数据对象集合（HashRef 或 ArrayRef）
# 逻辑：
#   1. 解析映射关系，生成列名与属性列表
#   2. 组装 SQL 插入语句
#   3. 遍历数据对象，展开单值/数组/哈希属性
#   4. 生成参数集合，调用 batchExecute 执行
#----------------------------------------------------------------------
sub batchInsert {
    my ($self, $columnMap, $tableName, $dataObjs) = @_;
    my ($attrWhichIsSingle, $attrWhichContainList, $attrTypes) = $self->parseColumnMap($columnMap);
    my @params;
    return if not defined $dataObjs;
    confess("错误: dataObjs 参数不是 hash 引用或 array 引用") if ref($dataObjs) !~ /^(?:HASH|ARRAY)$/o;

    # 提取列与属性
    my @columnsSingle = keys %$attrWhichIsSingle;
    my @attrsSingle = values %$attrWhichIsSingle;
    my @columnsList = keys %$attrWhichContainList;
    my @attrsList = values %$attrWhichContainList;
    my @columns = (@columnsSingle, @columnsList);

    # 构造 SQL 语句
    my @questionMarks = map {'?'} (0 .. $#columns);
    my $sqlString = "insert into $tableName (" . join(',', @columns) . ") values (" . join(',', @questionMarks) . ")";

    # 注意：从 Perl 5.012 起，values 可以处理数组或哈希引用
    for my $dataObj (values %{$dataObjs}) {
        my @param;
        my ($column, $attr);

        # 处理单值属性
        for my $i (0 .. $#columnsSingle) {
            ($column, $attr) = ($columnsSingle[$i], $attrsSingle[$i]);
            $param[$i] = $dataObj->$attr;
        }

        # 处理列表属性
        if (not defined $attrTypes) {
            push(@params, \@param);
        }
        else {
            my ($attrMembers, $maxAttrMemberNums) = $self->getAttrMembers($attrTypes, $dataObj);
            for my $j (0 .. $maxAttrMemberNums - 1) {
                for my $k (0 .. $#columnsList) {
                    $column = $columnsList[$k];
                    $attr = $attrsList[$k];
                    $param[$#columnsSingle + 1 + $k] = $attrMembers->{$attr}[$j];
                }
                push(@params, [ @param ]);
            }
        }
    }

    # 调用批量执行接口
    $self->batchExecute(\@params, $sqlString);
}

1;

# ABSTRACT: 数据库操作通用角色，提供批量插入和属性映射功能

=encoding utf8

=head1 NAME

PDK::DBI::Role - 通用数据库操作角色

=head1 SYNOPSIS

    package My::DB;
    use Moose;
    with 'PDK::DBI::Role';

    sub clone        { ... }
    sub batchExecute { ... }

    # 使用
    my $db = My::DB->new(
        dsn      => 'dbi:mysql:database=test;host=127.0.0.1;port=3306',
        user     => 'root',
        password => '123456',
    );

    # 批量插入
    $db->batchInsert(
        [ 'id', 'name', 'tags | @' ],
        'users',
        {
            u1 => User->new(id => 1, name => 'Tom', tags => [qw/a b/]),
            u2 => User->new(id => 2, name => 'Jerry', tags => [qw/x y z/])
        }
    );

=head1 DESCRIPTION

C<PDK::DBI::Role> 定义了一组通用数据库操作的属性与方法，
可被具体数据库适配模块（如 L<PDK::DBI::Mysql> 或 L<PDK::DBI::Oracle>）复用。

主要提供以下功能：

=over 4

=item *

数据库连接基本属性（dsn、user、password）

=item *

批量插入方法（L</batchInsert>）

=item *

列与对象属性映射关系解析（L</parseColumnMap>）

=item *

属性展开辅助方法（L</getAttrMembers>）

=back

=head1 ATTRIBUTES

=over 4

=item dsn

字符串，数据库连接字符串（必填）。

=item user

字符串，数据库用户名（必填）。

=item password

字符串，数据库密码（必填）。

=item dbi

延迟构建的 L<DBIx::Custom> 对象，由子类实现 C<_buildDbi> 方法生成。

=back

=head1 REQUIRED METHODS

=over 4

=item clone

克隆数据库对象。由具体实现类定义。

=item batchExecute

批量执行 SQL 的低层接口。由具体实现类定义。

=back

=head1 METHODS

=head2 getAttrMembers($attrTypes, $dataObj)

根据属性类型展开对象成员。

支持的类型：

=over 4

=item @

数组引用

=item %k

哈希键

=item %v

哈希值

=back

返回值：

=over 4

=item *

标量上下文：属性成员哈希引用

=item *

列表上下文：(属性成员哈希引用, 最大长度, 最小长度)

=back

=head2 parseColumnMap($columnMap)

解析列与对象属性的映射关系。

支持的映射格式：

    "column => attr | 类型"
    "column | 类型"
    "column"

返回值：

    (单值属性映射, 列表属性映射, 属性类型哈希)

=head2 batchInsert($columnMap, $tableName, $dataObjs)

批量插入数据。

参数说明：

=over 4

=item $columnMap

数组引用，定义列与属性的映射关系。

=item $tableName

字符串，目标表名。

=item $dataObjs

哈希引用或数组引用，存放数据对象。

=back

逻辑流程：

=over 4

=item 1

解析映射关系，生成列与属性列表。

=item 2

构造 SQL 插入语句。

=item 3

展开单值/数组/哈希属性，生成参数集合。

=item 4

调用 C<batchExecute> 执行批量插入。

=back

=head1 ERROR HANDLING

=over 4

=item *

若 C<$columnMap> 不是数组引用，抛出异常。

=item *

若 C<$dataObjs> 不是 HashRef 或 ArrayRef，抛出异常。

=item *

SQL 或属性展开失败时，将通过 C<Carp::confess> 抛出错误。

=back

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
