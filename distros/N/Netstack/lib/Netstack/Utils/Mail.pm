package Netstack::Utils::Mail;

#------------------------------------------------------------------------------
# 加载扩展模块功能
#------------------------------------------------------------------------------
use 5.016;
use Moose;
use namespace::autoclean;
use Mail::Sender;

#------------------------------------------------------------------------------
# 定义 Netstack::Utils::Mail 方法属性
#------------------------------------------------------------------------------
has smtp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has from => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has charset => (
  is      => 'ro',
  isa     => 'Str',
  builder => '_buildCharset',
);

has displayFormat => (
  is      => 'ro',
  isa     => 'Str',
  default => 'text/html',
);

#------------------------------------------------------------------------------
# _buildCharset 设置邮件编码格式
#------------------------------------------------------------------------------
sub _buildCharset {
  my $self = shift;
  my $charset;
  # 缺省编码为 GB2312
  if ( not defined $ENV{LANG} ) {
    $charset = 'gb2312';
  }
  elsif ( $ENV{LANG} =~ /(?:utf8|utf-8)$/io ) {
    $charset = 'utf8';
  }
  elsif ( $ENV{LANG} =~ /\b(gb\w+)$/io ) {
    $charset = $1;
  }
  else {
    $charset = 'gb2312';
  }
  return $charset;
}

=head3 sendmail

    # base64编码有长度限制，在一对解码标识符之间的字符串允许长度约为170，所以需要把标题分段插入解码标识。
    # 此分段依赖于base64编码的编码后每76个字符加一个回车的特性。
    if ( defined $param{subject} ) {
        $param{subject} =~s/(\s{1})/?=$1=?gb2312?b?/g;
    }

=cut

#------------------------------------------------------------------------------
# sendmail 发送邮件
#------------------------------------------------------------------------------
sub sendmail {
  my $self = shift;
  my %param;
  if ( ref $_[0] eq 'HASH' ) {
    %param = $_[0]->%*;
  }
  else {
    %param = @_;
  }
  # 异常拦截
  confess "ERROR: 必须定义邮件接收人" if not defined $param{to};

  # 处理收件人中的重复项
  $param{to} = join(
    ',', map { lc($_) }
      grep { defined $_ and $_ !~ /^\s*$/ }
      split( /[,;]/, $param{to} )
  );
  eval {
    # 初始化邮件对象
    my $sender = Mail::Sender->new(
      { smtp => $param{smtp} // $self->smtp,
        from => $param{from} // $self->from,
        to   => $param{to},
        cc   => $param{cc},
        #bcc => 'dengkuangda745@163.com',
        on_errors => 'die',
      }
    );
    # 设置邮件主体、编码
    $sender->Open(
      { subject  => $param{subject},
        ctype    => $param{ctype}    // $self->displayFormat . '; ' . $self->charset,
        encoding => $param{encoding} // "quoted-printable"
      }
    );
    # 执行邮件发送
    # for (@body) { $sender->SendEnc($_) };
    $sender->SendEnc( $param{msg} );
    $sender->Close();
  };

  if ( length($@) ) {
    $@ =~ s/\s+$//;
    confess $@;
  }
}

__PACKAGE__->meta->make_immutable;
1;
