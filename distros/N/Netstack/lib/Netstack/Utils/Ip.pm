package Netstack::Utils::Ip;

#------------------------------------------------------------------------------
# 加载扩展模块功能
#------------------------------------------------------------------------------
use 5.016;
use Moose;
use namespace::autoclean;
use Netstack::Utils::Set;

#------------------------------------------------------------------------------
# 定义 ipv4 正则表达式：单地址(1.1.1.1)、连续地址(1.1.1.1-2.2.2.2)和(1.1.1.1-10)
#------------------------------------------------------------------------------
has addrRegex => (
  is      => 'ro',
  default => sub {
    qr/^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx;
  }
);

#------------------------------------------------------------------------------
# 定义 rangeRegex 捕捉 1.1.1.1-2.2.2.2
#------------------------------------------------------------------------------
has rangeRegex => (
  is      => 'ro',
  default => sub {
    qr/^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx;
  },
);

#------------------------------------------------------------------------------
# 定义 subRangeRegex 捕捉 1.1.1.1-100
#------------------------------------------------------------------------------
has subRangeRegex => (
  is      => 'ro',
  default => sub {
    qr/^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx;
  },
);

#------------------------------------------------------------------------------
# 定义 ip/mask 正则表达式
#-----------------------------------------------------------------------------
has ipMask => (
  is      => 'ro',
  default => sub {
    qr/^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    \/
    (?:[1-9]|[12][0-9]|3[0-2])$/mx;
  },
);

#------------------------------------------------------------------------------
# 定义 addrWithRange 捕捉 1.1.1.1-2.2.2.2
#------------------------------------------------------------------------------
has ipRange => (
  is      => 'ro',
  default => sub {
    qr/(^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$)
    |
    (^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$)/mx;
  },
);

#------------------------------------------------------------------------------
# isIpv4 检验是否为 V4 地址
#------------------------------------------------------------------------------
sub isIpv4 {
  my $ip = shift || return;

  # Check for invalid chars
  unless ( $ip =~ m/^[\d\.]+$/ ) {
    return 0;
  }

  if ( $ip =~ m/^\./ ) {
    return 0;
  }

  if ( $ip =~ m/\.$/ ) {
    return 0;
  }

  # Single Numbers are considered to be IPv4
  if ( $ip =~ m/^(\d+)$/ and $1 < 256 ) { return 1 }

  # Count quads
  my $n = ( $ip =~ tr/\./\./ );

  # IPv4 must have from 1 to 4 quads
  unless ( $n >= 0 and $n < 4 ) {
    return 0;
  }

  # Check for empty quads
  if ( $ip =~ m/\.\./ ) {
    return 0;
  }

  foreach ( split /\./, $ip ) {
    # Check for invalid quads
    unless ( $_ >= 0 and $_ < 256 ) {
      return 0;
    }
  }
  return 1;
}

#------------------------------------------------------------------------------
# 定义 Netstack::Utils::Ip 方法属性
#------------------------------------------------------------------------------
sub getRangeFromIpRange {
  my ( $self, $ipMin, $ipMax ) = @_;
  # 入参检查
  confess __PACKAGE__ . "必须提供 ipRange (min, max)"
    unless ( defined $ipMin and defined $ipMax );
  confess __PACKAGE__ . "must provide two ipv4 object"
    unless ( isIpv4($ipMin) and isIpv4($ipMax) );

  # 将 ipaddr 转换为十进制
  my $min = $self->changeIpToInt($ipMin);
  my $max = $self->changeIpToInt($ipMax);
  # 返回计算结果
  return wantarray
    ? ( $min, $max )
    : Netstack::Utils::Set->new( $min, $max );
}

#------------------------------------------------------------------------------
# getRangeFromIpMask 通过 ip/mask掩码方式生成 IpSet 集合对象
#------------------------------------------------------------------------------
sub getRangeFromIpMask {
  my ( $self, $ip, $mask ) = @_;

  # 匹配 1.1.1.1-2.2.2.2 样式
  if (
    $ip =~ /^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx
    )
  {
    my ( $min, $max ) = split( /-/, $ip );
    return $self->getRangeFromIpRange( $min, $max );
  }
  # 匹配 1.1.1.1-30 样式
  elsif (
    $ip =~ /^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})
    -
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx
    )
  {
    my ( $min, $suffix ) = split( /-/, $ip );
    # 异常拦截
    confess __PACKAGE__ . "请正常填写$suffix，确保处于(0 .. 255)" if $suffix < 0 || $suffix > 255;
    my ($max) = $min =~ /^(\d+\.\d+\.\d+\.)/;
    $max .= $suffix;
    return $self->getRangeFromIpRange( $min, $max );
  }
  # 兜底的处理逻辑，兼容 1.1.1.1 或 1.1.1.1/32
  my $ipToInt = $self->changeIpToInt($ip);
  $mask = $self->changeMaskToNumForm( $mask // 32 );
  my $maskStr = ( '1' x $mask ) . ( '0' x ( 32 - $mask ) );
  my $min     = $ipToInt & oct( "0b" . $maskStr );
  my $max     = $min + oct( "0b" . ( '1' x ( 32 - $mask ) ) );
  # 返回计算结果
  return wantarray
    ? ( $min, $max )
    : Netstack::Utils::Set->new( $min, $max );
}

#------------------------------------------------------------------------------
# getNetIpFromIpMask
#------------------------------------------------------------------------------
sub getNetIpFromIpMask {
  my ( $self, $ip, $mask ) = @_;
  $mask = $self->changeMaskToNumForm($mask) // 32;

  # 检查是否主机ip
  return $ip if $mask == 32;
  # 非主机ip转换为10进制
  my $ipInt    = $self->changeIpToInt($ip);
  my $maskStr  = ( '1' x $mask ) . ( '0' x ( 32 - $mask ) );
  my $netIpNum = $ipInt & oct( "0b" . $maskStr );
  return $self->changeIntToIp($netIpNum);
}

#------------------------------------------------------------------------------
# changeIntToIp => # 168512809 变为 10.11.77.41
#------------------------------------------------------------------------------
sub changeIntToIp {
  my ( $self, $num ) = @_;
  # 入参校验
  confess "ERROR: 调用changeIntToIp异常，入参需保证在[0 .. 4294967295]之间"
    unless ( $num >= 0 and $num <= 4294967295 );
  # 将数字转为 32 位 二进制格式，每隔8位代表 IPV4 的一部分，使用 . 连结
  my $ipaddr = join(
    '.', map { oct( "0b" . $_ ) }
      split( /(?=(?:[01]{8})+$)/, sprintf( "%032b", $num ) )
  );
  # 返回计算结果
  return $ipaddr;
}

#------------------------------------------------------------------------------
# changeIpToInt => 把 10.11.77.41 变为 168512809
#------------------------------------------------------------------------------
sub changeIpToInt {
  my ( $self, $addr ) = @_;
  confess __PACKAGE__ . "必须提供正确的IPv4地址 $addr" unless defined $addr;
  # IPV4 样式判断
  unless (
    $addr =~ /^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
  (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx
    )
  {
    if ( $addr =~ /any|all/i ) {
      $addr = "0.0.0.0";
    }
    else {
      confess __PACKAGE__ . " ERROR: IP地址 ($addr) 格式有误, 调用函数changeIpToInt失败！";
    }
  }
  # 主体处理逻辑
  my @addr = map { ( not defined || /^\s*$/ ) ? 0 : $_ } split( /\./, $addr );
  confess __PACKAGE__ . "ipv4 $addr 解析异常，请正确提供IPV4地址" if scalar @addr != 4;
  my $ipNum = ( $addr[0] << 24 ) + ( $addr[1] << 16 ) + ( $addr[2] << 8 ) + $addr[3];

  # 返回计算结果
  return $ipNum;
}

#------------------------------------------------------------------------------
# changeMaskToNumForm => 把 255.255.255.0 变为 24
#------------------------------------------------------------------------------
sub changeMaskToNumForm {
  my ( $self, $mask ) = @_;
  # 入参校验
  confess __PACKAGE__ . "ERROR: 调用changeMaskToNumForm异常，请正确提供 mask，如255.0.0.0"
    unless defined $mask;

  if (
    $mask =~ /^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
  (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx
    )
  {
    my $IpStr = sprintf( "%032b", $self->changeIpToInt($mask) );
    if ( $IpStr =~ /01/ ) {
      confess "ERROR: 函数changeMaskToNumForm入参校验不通过，请正确填写入参";
    }
    elsif ( $IpStr =~ /^(1+)/ ) {
      $mask = length($1);
    }
    else {
      $mask = 0;
    }
  }
  elsif ( $mask !~ /^\d+$/o ) {
    confess __PACKAGE__ . "ERROR: 调用changeMaskToNumForm异常，转换后的掩码必须为[1..32]的数字";
  }
  # 边界条件判断
  if ( $mask < 0 or $mask > 32 ) {
    confess __PACKAGE__ . "ERROR: 调用changeMaskToNumForm异常，IPV4掩码越限需保证在[1..32]";
  }
  # 返回计算结果
  return $mask;
}

#------------------------------------------------------------------------------
# changeWildcardToMaskForm => 反掩码转换为正掩码，如0.0.0.255 改为255.0.0.0
#------------------------------------------------------------------------------
sub changeWildcardToMaskForm {
  my ( $self, $wildcard ) = @_;
  if (
    $wildcard =~ /(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/mx
    )
  {
    my ( $p1, $p2, $p3, $p4 ) = ( $1 ^ 255, $2 ^ 255, $3 ^ 255, $4 ^ 255 );
    my $mask = "$p1.$p2.$p3.$p4";
    return $mask;
  }
  else {
    confess __PACKAGE__ . "ERROR: 调用changeWildcardToMaskForm异常，请正确填写反掩码";
  }
}

#------------------------------------------------------------------------------
# changeMaskToIpForm => 掩码转IP格式，如把 24 变为 255.255.255.0
#------------------------------------------------------------------------------
sub changeMaskToIpForm {
  my ( $self, $mask ) = @_;

  # 本身就匹配正则表达式
  if (
    $mask =~ /^(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}
    (?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$/mx
    )
  {
    return $mask;
  }
  # 处于正常区间
  elsif ( $mask >= 0 and $mask <= 32 ) {
    my $maskString = ( '1' x $mask ) . ( '0' x ( 32 - $mask ) );
    my @ip         = $maskString =~ /([01]{8})/g;
    # 数组组装成 ipv4
    my $addr = join( ".", map { oct( "0b" . $_ ) } @ip );
    return $addr;
  }
  else {
    confess __PACKAGE__ . "ERROR: 调用changeMaskToIpForm异常，请正确填写掩码格式";
  }
}

#------------------------------------------------------------------------------
# getIpMaskFromRange => 转换 IpSet 为 Subnet
#------------------------------------------------------------------------------
sub getIpMaskFromRange {
  my ( $self, $min, $max ) = @_;
  # 入参检查
  confess "调用函数getIpMaskFromRange失败，请正确提供 min max "
    if not defined $min || not defined $max;
  # 异常拦截
  confess "请正确填写 min max 区间值，必须介于 (0 .. 4294967295)之间"
    unless ( $min >= 0 and $min <= 4294967295 )
    and ( $max >= 0 || $max <= 4294967295 );

  # 将最小值转为 IPADDR
  my $minIp = $self->changeIntToIp($min);
  # 集合区间计数
  my $range = $max - $min + 1;
  my $mask  = int( 32 - log($range) / log(2) );
  # TODOS：数学计算
  if (  $min == ( $min & ( ( 1 << 32 ) - ( 1 << ( 32 - $mask ) ) ) )
    and $max == $min + ( 1 << ( 32 - $mask ) ) - 1 )
  {
    return $minIp . '/' . $mask;
  }
  else {
    return $minIp . '-' . $self->changeIntToIp($max);
  }
}

#------------------------------------------------------------------------------
# getRangeFromService => Services 切割
#------------------------------------------------------------------------------
sub getRangeFromService {
  my ( $self, $service ) = @_;
  # 异常拦截
  confess __PACKAGE__ . " Error: 必须提供服务端口如TCP/80"
    unless defined $service;
  # 切割变量
  my ( $proto, $port ) = split( '/', $service );

  # 边界条件处理
  my $protoNum;
  if ( $proto eq '0' or $proto =~ /any|all/i ) {
    return wantarray
      ? ( 0, 16777215 )
      : Netstack::Utils::Set->new( 0, 16777215 );
  }
  elsif ( $proto =~ /tcp|udp|icmp|\d+/i ) {
    if ( $proto =~ /tcp/i ) {
      $protoNum = 6;
    }
    elsif ( $proto =~ /udp/i ) {
      $protoNum = 17;
    }
    elsif ( $proto =~ /icmp/i ) {
      $protoNum = 1;
    }
    elsif ( $proto =~ /\d+/i ) {
      $protoNum = $proto;
    }
  }
  # 协议代码移位计算
  my $protoValue = $protoNum << 16;

  my ( $min, $max );
  if ( defined $port ) {
    ( $min, $max ) = split( /-|\s+/, $port );
    $max //= $min;
    confess __PACKAGE__ . "必须确保服务端口处于区间 (0 .. 65535)"
      unless ( $min >= 0 and $min <= 65535 )
      and ( $max >= 0 and $max <= 65535 );
  }
  else {
    $min = 0;
    $max = 0;
  }
  return wantarray
    ? ( $protoValue + $min, $protoValue + $max )
    : Netstack::Utils::Set->new( $protoValue + $min, $protoValue + $max );
}

__PACKAGE__->meta->make_immutable;
1;
