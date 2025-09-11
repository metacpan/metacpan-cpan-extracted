package PDK::Utils::Context;

use utf8;
use v5.30;
use Moose;
use Digest::MD5;
use namespace::autoclean;
use Encode::Guess;
use PDK::Utils::Date;
use Carp;

our $VERSION = '0.005';

# 配置内容数组
has config => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

# 配置内容字符串
has content => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_buildContent',
);

# 当前解析位置游标
has cursor => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

# 重写配置签名属性
has confSign => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    builder  => '_buildConfSign',
);

# 重写时间戳属性
has timestamp => (
    is       => 'ro',
    required => 0,
    builder  => '_buildTimestamp',
);

# 行解析标志数组
has lineParsedFlags => (
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    builder => '_buildLineParsedFlags',
);

# 构建配置签名(MD5哈希)
sub _buildConfSign {
    my $self = shift;
    return Digest::MD5::md5_hex(join("\n", @{$self->config}));
}

# 构建配置内容字符串
sub _buildContent {
    my $self = shift;
    my $content = join("\n", @{$self->config});
    return $content;
}

# 构建时间戳
sub _buildTimestamp {
    my $self = shift;
    return PDK::Utils::Date->new->getFormatedDate;
}

# 构建行解析标志数组
sub _buildLineParsedFlags {
    my $self = shift;
    return ([ map {0} (1 .. @{$self->config}) ]);
}

# 跳转到配置开头
sub goToHead {
    my $self = shift;
    $self->{cursor} = 0;
}

# 获取下一行配置
sub nextLine {
    my $self = shift;

    my $result = undef;

    if ($self->cursor < scalar(@{$self->config})) {
        $result = $self->config->[$self->cursor];
        $self->{cursor}++;
    }

    return $result;
}

# 获取上一行配置
sub prevLine {
    my $self = shift;
    if ($self->{cursor} > 0) {
        $self->{cursor}--;
        return 1;
    }
    else {
        warn "错误: prevLine 失败，游标已在开头\n";
        return undef;
    }
}

# 获取下一个未解析的行
sub nextUnParsedLine {
    my $self = shift;

    my $result = undef;
    while ($self->cursor < scalar(@{$self->config}) and $self->getParseFlag == 1) {
        $self->{cursor}++;
    }

    if ($self->cursor < scalar(@{$self->config})) {
        $result = $self->config->[$self->cursor];
        while (not defined $result or $result =~ /^\s*$/) {
            $self->setParseFlag(1);
            $self->{cursor}++;
            while ($self->cursor < scalar(@{$self->config}) and $self->getParseFlag == 1) {
                $self->{cursor}++;
            }
            if ($self->cursor < scalar(@{$self->config})) {
                $result = $self->config->[$self->cursor];
            }
            else {
                return undef;
            }

        }
        $self->setParseFlag(1);
        $self->{cursor}++;
    }
    chomp $result if defined $result;

    my $enc = Encode::Guess->guess($result);
    if (ref $enc) {
        eval {$result = $enc->decode($result);};
        if (!!$@) {
            confess "[获取下一行配置] 字符串解码失败：$@";
        }
    }
    else {
        warn "[获取下一行配置] 无法正常解码，直接使用原字符串编码";
    }
    return $result;
}

# 回溯到上一个解析点
sub backtrack {
    my $self = shift;

    if ($self->{cursor} > 0) {
        $self->{cursor}--;
        $self->setParseFlag(0);
        return 1;
    }
    else {
        warn "错误: backtrack 失败，游标已在开头\n";
        return undef;
    }
}

# 忽略当前行
sub ignore {
    my $self = shift;
    if ($self->cursor == 0) {
        return $self->nextLine;
    } else {
        $self->backtrack and return $self->nextLine;
    }
}

# 获取所有未解析的行
sub getUnParsedLines {
    my $self = shift;
    my $unParsedLines = join('', map {$self->config->[$_]} grep {$self->{lineParsedFlags}->[$_] == 0} (0 .. scalar(@{$self->config}) - 1));
    return $unParsedLines;
}

# 获取当前行的解析标志
sub getParseFlag {
    my $self = shift;
    if ($self->cursor >= 0 and $self->cursor < scalar(@{$self->config})) {
        return $self->{lineParsedFlags}->[$self->cursor];
    }
    else {
        return;
    }
}

# 设置当前行的解析标志
sub setParseFlag {
    my ($self, $flag) = @_;
    if ($self->cursor >= 0 and $self->cursor < scalar(@{$self->config})) {
        $self->{lineParsedFlags}->[$self->cursor] = $flag // 1;
        return 1;
    }
    else {
        return;
    }
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 NAME

PDK::Utils::Context - 配置解析上下文工具类

=head1 SYNOPSIS

    use PDK::Utils::Context;

    my $ctx = PDK::Utils::Context->new(config => [
        "line1",
        "line2",
        "line3",
    ]);

    say $ctx->confSign;   # 打印配置签名（MD5）
    say $ctx->timestamp;  # 打印时间戳

    # 逐行解析
    while (my $line = $ctx->nextUnParsedLine) {
        say "解析: $line";
    }

    # 回溯与忽略
    $ctx->backtrack;
    $ctx->ignore;

=head1 DESCRIPTION

该模块用于管理和解析配置内容，提供游标控制、行解析标志、签名生成、时间戳管理等功能，方便逐行读取和回溯。

=head1 ATTRIBUTES

=head2 config

    isa => ArrayRef[Str]
    is  => 'ro'
    required => 1

配置内容数组，每个元素代表一行配置。

=head2 content

    isa  => Str
    is   => 'ro'
    lazy => 1

配置内容字符串，默认由 C<config> 数组拼接生成。

=head2 cursor

    isa     => Int
    is      => 'ro'
    default => 0

当前解析游标，指向配置中的当前位置。

=head2 confSign

    is      => 'ro'
    lazy    => 1

配置签名，基于配置内容的 MD5 哈希生成。

=head2 timestamp

    is      => 'ro'
    lazy    => 1

时间戳，使用 L<PDK::Utils::Date> 生成的格式化日期时间字符串。

=head1 METHODS

=head2 goToHead

    $ctx->goToHead();

游标回到配置的开头（位置 0）。

=head2 nextLine

    my $line = $ctx->nextLine();

获取下一行配置，并将游标向前移动一行。若已到末尾则返回 undef。

=head2 prevLine

    $ctx->prevLine();

游标回退一行，若已在开头则返回 undef 并产生警告。

=head2 nextUnParsedLine

    my $line = $ctx->nextUnParsedLine();

获取下一个未解析的配置行，并将其标记为已解析。自动跳过空行或空白内容。
支持自动检测并尝试解码字符集。

=head2 backtrack

    $ctx->backtrack();

回溯到上一个解析点，并将该行的解析标志清除。

=head2 ignore

    $ctx->ignore();

忽略当前行，等价于 C<backtrack> 然后 C<nextLine>。

=head2 getUnParsedLines

    my $lines = $ctx->getUnParsedLines();

获取所有未解析的配置行，返回字符串。

=head2 getParseFlag

    my $flag = $ctx->getParseFlag();

获取当前行的解析标志（0 表示未解析，1 表示已解析）。

=head2 setParseFlag

    $ctx->setParseFlag(1);

设置当前行的解析标志，默认为 1。

=head1 ERROR HANDLING

=over 4

=item *

解码失败时会抛出异常或产生警告。

=item *

游标越界时（如 prevLine / backtrack 在开头调用），会返回 undef 并产生警告。

=back

=head1 EXAMPLES

    use PDK::Utils::Context;

    my $ctx = PDK::Utils::Context->new(config => [
        "line1",
        "line2",
        "line3",
    ]);

    say $ctx->confSign;   # 打印配置签名（MD5）
    say $ctx->timestamp;  # 打印时间戳

    # 逐行解析
    while (my $line = $ctx->nextUnParsedLine) {
        say "解析: $line";
    }

    # 回溯与忽略
    $ctx->backtrack;
    $ctx->ignore;

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
