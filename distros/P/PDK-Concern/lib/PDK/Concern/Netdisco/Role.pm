package PDK::Concern::Netdisco::Role;

use utf8;
use v5.30;
use Moose::Role;
use Carp qw(croak);
use namespace::autoclean;
use File::Path qw(make_path);

requires 'gen_iface_desc';
requires 'commands';

has device => (is => 'ro', does => 'PDK::Device::Role', required => 1,);

has month => (
  is      => 'ro',
  default => sub {
    my $month = `date +%Y-%m`;
    chomp($month);
    return $month;
  },
);

has date => (
  is      => 'ro',
  default => sub {
    my $date = `date +%Y-%m-%d`;
    chomp($date);
    return $date;
  },
);

has workdir => (is => 'rw', default => sub { $ENV{PDK_CONCERN_NETDISCO_HOME} // glob("~") },);

has debug => (is => 'rw', isa => 'Int', default => sub { $ENV{PDK_CONCERN_NETDISCO_DEBUG} // 0 },);

sub now {
  my $now = `date "+%Y-%m-%d %H:%M:%S"`;
  chomp($now);
  return $now;
}

sub dump {
  my ($self, $msg) = @_;

  $msg .= ';' unless $msg =~ /^\s*$/ || $msg =~ /[,，！!。.]$/;

  my $text = $self->now() . " - [debug] $msg";
  if ($self->debug == 1) {
    say $text;
  }
  elsif ($self->debug > 1) {
    my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
    make_path($workdir) unless -d $workdir;

    my $filename = "$workdir/$self->{device}{host}.txt";
    open(my $fh, '>>:encoding(UTF-8)', $filename) or croak "无法打开文件 $filename 进行写入: $!";
    print $fh "$text\n"                           or croak "写入文件 $filename 失败: $!";
    close($fh)                                    or croak "关闭文件句柄 $filename 失败: $!";
  }
}

sub write_file {
  my ($self, $config, $name) = @_;

  croak("必须提供非空配置信息") unless !!$config;

  $name //= $self->{device}{host} . ".txt";
  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
  make_path($workdir) unless -d $workdir;

  my $enc = Encode::Guess->guess($config);
  if (ref($enc)) {
    eval { $config = $enc->decode($config); };
    if (!!$@) {
      $self->dump("[write_file] $name 字符串解码失败：$@");
    }
  }
  else {
    $self->dump("[write_file] $name 无法猜测编码: $enc");
  }

  my $filename = "$workdir/$name";
  $self->dump("[write_file] 准备将数据写入本地文件: ($workdir/$name)");

  open(my $fh, '>>encoding(UTF-8)', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $config                            or croak "写入文件 $filename 失败: $!";
  close($fh)                                   or croak "关闭文件句柄 $filename 失败: $!";

  $self->dump("已将配置文件写入文本文件: $filename");

  return {success => 1};
}

sub explore_topology {
  my ($self) = @_;

  my $device = $self->device;

  my $result = $device->execCommands($self->commands);
  if ($result->{success}) {
    my @topology = split(/\n/, $result->{result});
    my @commands = $self->gen_iface_desc(\@topology);
    return $device->execCommands(\@commands);
  }
  else {
    return {success => 0, reason => $result->{reason}};
  }
}

sub refine_if {
  my ($self, $name) = @_;

  $name =~ s/Ten-GigabitEthernet/TE/gi;
  $name =~ s/GigabitEthernet/GE/gi;
  $name =~ s/Smartrate-Ethernet/SE/gi;
  $name =~ s/Ethernet/Eth/gi;
  $name =~ s/xethernet/XE/gi;
  $name =~ s/ethernet/E/gi;
  $name =~ s/^xge/TE/gi;
  $name =~ s/^sge/SE/gi;
  $name =~ s/Twe/TW/gi;
  $name =~ s/eth/Eth/gi;
  $name =~ s/^ge/G/gi;

  return $name;
}

1;

# ABSTRACT: Based Moose for network device discovery and management
