package PDK::Utils::Ip;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Utils::Set;
use Data::Validate::IP qw/is_ipv4/;

#------------------------------------------------------------------------------
# 将连续地址转换为集合对象
#------------------------------------------------------------------------------
sub getRangeFromIpRange {
  my ($self, $ipMin, $ipMax) = @_;
  confess "Must provide two ipaddr, but with $ipMin - $ipMax" unless (is_ipv4($ipMin) and is_ipv4($ipMax));

  my $min = $self->changeIpToInt($ipMin);
  my $max = $self->changeIpToInt($ipMax);
  return (wantarray ? ($min, $max) : PDK::Utils::Set->new($min, $max));
}

#------------------------------------------------------------------------------
# 将IP/MASK样式转换为集合对象
#------------------------------------------------------------------------------
sub getRangeFromIpMask {
  my ($self, $ip, $mask) = @_;
  if ($ip
    =~ /(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])-(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/
    )
  {
    my ($ipMin, $ipMax) = ("$1.$2.$3.$4", "$1.$2.$3.$5");
    return $self->getRangeFromIpRange($ipMin, $ipMax);
  }
  $ip   = $self->changeIpToInt($ip);
  $mask = $self->changeMaskToNumForm($mask // 32);
  my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
  my $min        = $ip & oct("0b" . $maskString);
  my $max        = $min + oct("0b" . ('1' x (32 - $mask)));
  return (wantarray ? ($min, $max) : PDK::Utils::Set->new($min, $max));
}

#------------------------------------------------------------------------------
# 将IP/MASK样式转换为网段号
#------------------------------------------------------------------------------
sub getNetIpFromIpMask {
  my ($self, $ip, $mask) = @_;
  $mask = $self->changeMaskToNumForm($mask // 32);
  confess "Netmask but between 0 .. 32" unless ($mask >= 0 and $mask <= 32);

  if ($mask == 32) {
    return $ip;
  }
  else {
    $ip = $self->changeIpToInt($ip);
    my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
    my $netIpNum   = $ip & oct("0b" . $maskString);
    return $self->changeIntToIp($netIpNum);
  }
}

#------------------------------------------------------------------------------
# 将十进制数转换为 IP
# 把 168512809 变为 10.11.77.41
#------------------------------------------------------------------------------
sub changeIntToIp {
  my ($self, $num) = @_;
  confess "Number must in 0 .. 4294967295 " unless ($num >= 0 and $num <= 4294967295);

  my $ip = join('.', map { oct("0b" . $_) } split(/(?=(?:[01]{8})+$)/, sprintf("%032b", $num)));
  return $ip;
}

#------------------------------------------------------------------------------
# 将IP转换为十进制
# 把 10.11.77.41 变为 168512809
#------------------------------------------------------------------------------
sub changeIpToInt {
  my ($self, $ip) = @_;
  unless (is_ipv4($ip)) {
    if ($ip =~ /any/i) {
      $ip = "0.0.0.0";
    }
    else {
      confess "$ip is not ipv4 address";
    }
  }
  my @ips   = map { (!defined || /^\s*$/) ? 0 : $_ } split(/\./, $ip);
  my $ipNum = ($ips[0] << 24) + ($ips[1] << 16) + ($ips[2] << 8) + $ips[3];
  return $ipNum;
}

#------------------------------------------------------------------------------
# 将掩码转换为 0-32 计数
# 把 255.255.255.0 变为 24
#------------------------------------------------------------------------------
sub changeMaskToNumForm {
  my ($self, $mask) = @_;
  confess "ERROR: 必须输入掩码信息" if not defined $mask;

  if (is_ipv4($mask)) {
    my $string = sprintf("%032b", $self->changeIpToInt($mask));
    if ($string =~ /01/) {
      confess "ERROR: 网络掩码 [$mask] 格式有误, 调用函数changeMaskToNumForm失败！";
    }
    elsif ($string =~ /^(1+)/) {
      $mask = length($1);
    }
    else {
      $mask = 0;
    }
  }
  elsif ($mask !~ /^\d+$/o) {
    confess "ERROR: 网络掩码 [$mask] 格式有误, 调用函数changeMaskToNumForm失败！";
  }

  if ($mask < 0 or $mask > 32) {
    confess "ERROR: 网络掩码 [$mask] 未命中掩码正常区间值, 调用函数changeMaskToNumForm失败！";
  }
  return $mask;
}

#------------------------------------------------------------------------------
# 将反掩码转换为正掩码格式
# 为了方便计算将反掩码改为掩码如 0.0.0.255 改为 255.0.0.0
#------------------------------------------------------------------------------
sub changeWildcardToMaskForm {
  my ($self, $wildcard) = @_;
  if ($wildcard
    =~ /^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$/
    )
  {
    my ($p1, $p2, $p3, $p4) = ($1 ^ 255, $2 ^ 255, $3 ^ 255, $4 ^ 255);
    my $mask = "$p1.$p2.$p3.$p4";
    return $mask;
  }
  else {
    confess "ERROR: 反掩码 [$wildcard] 格式有误， 调用函数changeWildcardToMaskForm失败！";
  }
}

#------------------------------------------------------------------------------
# 将掩码号转换为IP样式
# 把 24 变为 255.255.255.0
#------------------------------------------------------------------------------
sub changeMaskToIpForm {
  my ($self, $mask) = @_;
  if (is_ipv4($mask)) {
    return $mask;
  }
  elsif ($mask >= 0 and $mask <= 32) {
    my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
    my @ip         = $maskString =~ /([01]{8})/g;
    my $ip         = join(".", map { oct("0b" . $_) } @ip);
    return $ip;
  }
  else {
    confess "ERROR: 网络掩码 [$mask] 格式有误, 调用函数changeMaskToIpForm失败！";
  }
}

#------------------------------------------------------------------------------
# 将掩码号转换为IP样式
# 把 24 变为 255.255.255.0
#------------------------------------------------------------------------------
sub getIpMaskFromRange {
  my ($self, $min, $max) = @_;
  my $minIp;
  if (not defined $max) {
    confess "\$max 没有定义, 调用函数getIpMaskFromRange失败！";
  }
  $minIp = $self->changeIntToIp($min);
  my $temp = $max - $min + 1;
  my $mask = int(32 - log($temp) / log(2));
  if ($min == ($min & ((1 << 32) - (1 << (32 - $mask)))) and $max == $min + (1 << (32 - $mask)) - 1) {
    return $minIp . '/' . $mask;
  }
  else {
    return $minIp . '-' . $self->changeIntToIp($max);
  }
}

#------------------------------------------------------------------------------
# 将服务端口转换为集合对象
# 把 24 变为 255.255.255.0
#------------------------------------------------------------------------------
sub getRangeFromService {
  my ($self,  $service) = @_;
  my ($proto, $port)    = split('/', $service);
  my $protoValue = 0;
  if ($proto eq '0' or $proto =~ /any/i) {
    return (wantarray ? (0, 16777215) : PDK::Utils::Set->new(0, 16777215));
  }
  elsif ($proto =~ /tcp|udp|icmp|\d+/i) {
    my $protoNum = 0;
    if ($proto =~ /tcp/i) {
      $protoNum = 6;
    }
    elsif ($proto =~ /udp/i) {
      $protoNum = 17;
    }
    elsif ($proto =~ /icmp/i) {
      $protoNum = 1;
    }
    elsif ($proto =~ /\d+/i) {
      $protoNum = $proto;
    }
    $protoValue = ($protoNum << 16);
  }
  my ($portMin, $portMax);
  if (defined $port) {
    ($portMin, $portMax) = split(/-|\s+/, $port);
    $portMax = $portMin if not defined $portMax or $portMax =~ /^\s*/s;
  }
  else {
    $portMin = 0;
    $portMax = 0;
  }
  return (
    wantarray
    ? ($protoValue + $portMin, $protoValue + $portMax)
    : PDK::Utils::Set->new($protoValue + $portMin, $protoValue + $portMax));
}

__PACKAGE__->meta->make_immutable;
1;
