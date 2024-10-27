package PDK::Utils::Ip;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use PDK::Utils::Set;

sub getRangeFromIpRange {
  my ($self, $ipMin, $ipMax) = @_;

  my $min = $self->changeIpToInt($ipMin);
  my $max = $self->changeIpToInt($ipMax);

  return wantarray ? ($min, $max) : PDK::Utils::Set->new($min, $max);
}

sub getRangeFromIpMask {
  my ($self, $ip, $mask) = @_;
  my $format = '\d+\.\d+\.\d+\.\d+';

  if ($ip =~ /$format-$format/) {
    my ($ipMin, $ipMax) = split('-', $ip);
    return $self->getRangeFromIpRange($ipMin, $ipMax);
  }

  $ip   = $self->changeIpToInt($ip);
  $mask = $self->changeMaskToNumForm($mask // 32);

  my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
  my $min        = $ip & oct("0b$maskString");
  my $max        = $min + oct("0b" . ('1' x (32 - $mask)));

  return wantarray ? ($min, $max) : PDK::Utils::Set->new($min, $max);
}

sub getNetIpFromIpMask {
  my ($self, $ip, $mask) = @_;
  $mask = $self->changeMaskToNumForm($mask // 32);

  my $netIp;
  if ($mask == 32) {
    $netIp = $ip;
  }
  else {
    $ip = $self->changeIpToInt($ip);
    my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
    my $netIpNum   = $ip & oct("0b$maskString");
    $netIp = $self->changeIntToIp($netIpNum);
  }
  return $netIp;
}

sub changeIntToIp {
  my ($self, $num) = @_;
  my $ip = join('.', map { oct("0b$_") } split(/(?<=[01])(?=(?:[01]{8})+$)/, sprintf("%032b", $num)));
  return $ip;
}

sub changeIpToInt {
  my ($self, $ip) = @_;
  if ($ip !~ /^\d+\.\d+\.\d+\.\d+$/o) {
    if ($ip =~ /any/i) {
      $ip = "0.0.0.0";
    }
    else {
      confess("错误: IP $ip 非法");
    }
  }
  my @ips   = map { not defined or /^\s*$/ ? 0 : $_ } split(/\./, $ip, 4);
  my $ipNum = ($ips[0] << 24) + ($ips[1] << 16) + ($ips[2] << 8) + $ips[3];
  return $ipNum;
}

sub changeMaskToNumForm {
  my ($self, $mask) = @_;
  confess("错误: 掩码未定义") if not defined $mask;
  if ($mask =~ /^\d+\.\d+\.\d+\.\d+$/o) {
    my $string = sprintf("%032b", $self->changeIpToInt($mask));
    if ($string =~ /01/) {
      confess("错误: 掩码 $mask 非法");
    }
    elsif ($string =~ /^(1+)/) {
      $mask = length($1);
    }
    else {
      $mask = 0;
    }
  }
  elsif ($mask !~ /^\d+$/o) {
    confess("错误: 掩码值 [$mask] 格式错误");
  }
  if ($mask < 0 or $mask > 32) {
    confess("错误: 掩码 $mask 非法");
  }
  return $mask;
}

sub changeWildcardToMaskForm {
  my ($self, $wildcard) = @_;
  if ($wildcard =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
    my ($p1, $p2, $p3, $p4) = ($1 ^ 255, $2 ^ 255, $3 ^ 255, $4 ^ 255);
    my $mask = "$p1.$p2.$p3.$p4";
    return $mask;
  }
  else {
    return undef;
  }
}

sub changeMaskToIpForm {
  my ($self, $mask) = @_;
  my $ip = '';
  if ($mask =~ /^\d+\.\d+\.\d+\.\d+$/o) {
    $ip = $mask;
  }
  elsif ($mask >= 0 and $mask <= 32) {
    my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
    my @ip         = $maskString =~ /([01]{8})(?=(?:[01]{8})*$)/g;
    $ip .= oct("0b$_") . "." for @ip[0 .. 3];
    chop($ip);
  }
  else {
    confess("错误: 掩码 $mask 非法");
  }
  return $ip;
}

sub getIpMaskFromRange {
  my ($self, $min, $max) = @_;
  confess("未定义最大值") if not defined $max;
  my $minIp = $self->changeIntToIp($min);
  my $temp  = $max - $min + 1;
  my $mask = int(32 - log($temp) / log(2));
  if ($min == ($min & ((1 << 32) - (1 << (32 - $mask)))) and $max == $min + (1 << (32 - $mask)) - 1) {
    return $minIp . '/' . $mask;
  }
  else {
    return $minIp . '-' . $self->changeIntToIp($max);
  }
}

sub getRangeFromService {
  my ($self,  $service) = @_;
  my ($proto, $port)    = split('/', $service);
  my $protoValue;
  if ($proto eq '0' or $proto =~ /any/i) {
    return wantarray ? (0, 16777215) : PDK::Utils::Set->new(0, 16777215);
  }
  elsif ($proto =~ /tcp|udp|icmp|\d+/i) {
    my $protoNum;
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
    $portMin = $portMax = 0;
  }
  return
    wantarray
    ? ($protoValue + $portMin, $protoValue + $portMax)
    : PDK::Utils::Set->new($protoValue + $portMin, $protoValue + $portMax);
}

__PACKAGE__->meta->make_immutable;

1;
