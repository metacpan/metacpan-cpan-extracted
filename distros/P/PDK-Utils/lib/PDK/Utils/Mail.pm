package PDK::Utils::Mail;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use Mail::Sender;
use Carp;

our $VERSION = '0.005';

# SMTP服务器地址
has smtp => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# 发件人地址
has from => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# 字符编码
has charset => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_buildCharset',
);

# 邮件显示格式
has displayFormat => (
    is      => 'ro',
    isa     => 'Str',
    default => 'text/html',
);

# 构建字符编码
sub _buildCharset {
    my $self = shift;
    my $charset;

    # 根据系统环境变量LANG确定字符编码
    if (not defined $ENV{LANG}) {
        $charset = 'gb2312';
    }
    elsif ($ENV{LANG} =~ /(?:utf8|utf-8)$/io) {
        $charset = 'utf8';
    }
    elsif ($ENV{LANG} =~ /\b(gb\w+)$/io) {
        $charset = $1;
    }
    else {
        $charset = 'gb2312';
    }
    return $charset;
}

# 发送邮件
sub sendmail {
    my $self = shift;

    my %param;
    # 支持哈希引用或参数列表两种调用方式
    if (ref($_[0]) eq 'HASH') {
        %param = %{$_[0]};
    }
    else {
        %param = @_;
    }

    # 检查收件人地址
    confess("错误: 缺少收件人地址") if not defined $param{to};

    # 处理收件人中的重复项
    my %uniq = map { lc($_) => 1 } grep { defined $_ && $_ !~ /^\s*$/ } split(/[,;]/, $param{to});
    $param{to} = join(',', keys %uniq);

    # 发送邮件
    eval {
        my $sender = Mail::Sender->new({
            smtp          => $param{smtp} // $self->smtp,
            from          => $param{from} // $self->from,
            to            => $param{to},
            cc            => $param{cc},
            on_errors     => 'die', # 出错时抛出异常
        });

        # 打开邮件连接并设置邮件头
        $sender->Open({
            subject  => $param{subject},
            ctype    => $param{ctype} // $self->displayFormat . '; ' . $self->charset,
            encoding => $param{encoding} // "quoted-printable", # 使用可打印编码
        });

        # 发送邮件内容
        $sender->SendEnc($param{msg});

        # 关闭邮件连接
        $sender->Close();
    };

    # 处理发送过程中的错误
    if ($@) {
        $@ =~ s/\s+$//;
        confess($@);
    }
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 NAME

PDK::Utils::Mail - 邮件发送工具类

=head1 SYNOPSIS

    use PDK::Utils::Mail;

    my $mailer = PDK::Utils::Mail->new(
        smtp => 'smtp.example.com',
        from => 'noreply@example.com',
    );

    eval {
        $mailer->sendmail(
            to      => 'user1@example.com;user2@example.com',
            cc      => 'manager@example.com',
            subject => '测试邮件',
            msg     => '<h1>Hello, World!</h1>',
        );
    };
    if ($@) {
        warn "邮件发送失败: $@";
    }

=head1 DESCRIPTION

该模块基于 L<Mail::Sender>，提供简洁的邮件发送接口，支持 SMTP、收件人去重、字符编码自动识别等功能。

=head1 ATTRIBUTES

=over 4

=item smtp

字符串类型，SMTP 服务器地址（必填）。

=item from

字符串类型，发件人地址（必填）。

=item charset

字符串类型，字符编码。
默认根据环境变量 C<LANG> 自动推断，支持 utf8、gb2312 等。
若无法识别，则默认为 gb2312。

=item displayFormat

字符串类型，邮件内容格式，默认值为 C<text/html>。

=back

=head1 METHODS

=head2 sendmail(\%param | %param)

发送邮件。支持两种调用方式：传入哈希引用或参数列表。

支持参数：

=over 8

=item * smtp - SMTP 服务器地址（可覆盖对象默认值）

=item * from - 发件人地址（可覆盖对象默认值）

=item * to - 收件人地址，支持逗号或分号分隔，模块会自动去重

=item * cc - 抄送地址（可选）

=item * subject - 邮件主题

=item * msg - 邮件正文

=item * ctype - 邮件内容类型，默认使用对象的 C<displayFormat> 与 C<charset>

=item * encoding - 邮件正文编码方式，默认 C<quoted-printable>

=back

=head1 ERROR HANDLING

=over 4

=item *

缺少收件人地址时会抛出异常。

=item *

邮件发送失败时，会抛出 L<Carp::confess> 异常，并包含错误信息。

=back

=head1 EXAMPLES

    use PDK::Utils::Mail;

    my $mailer = PDK::Utils::Mail->new(
        smtp => 'smtp.example.com',
        from => 'noreply@example.com',
    );

    eval {
        $mailer->sendmail(
            to      => 'user1@example.com;user2@example.com',
            cc      => 'manager@example.com',
            subject => '测试邮件',
            msg     => '<h1>Hello, World!</h1>',
        );
    };
    if ($@) {
        warn "邮件发送失败: $@";
    }

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut

