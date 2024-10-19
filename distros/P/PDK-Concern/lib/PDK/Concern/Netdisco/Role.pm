package PDK::Concern::Netdisco::Role;

use v5.30;
use Moose::Role;
use Carp qw(croak);
use namespace::autoclean;
use File::Path qw(make_path);

requires 'gen_iface_desc';
requires 'commands';

has device => (is => 'ro', does => 'PDK::Device::Base', required => 1,);

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

has workdir => (is => 'rw', default => sub { $ENV{PDK_CONCERN_HOME} // glob("~") },);

has debug => (is => 'rw', default => sub { $ENV{PDK_CONCERN_DEBUG} // 0 },);

sub now {
  my $now = `date "+%Y-%m-%d %H:%M:%S"`;
  chomp($now);
  return $now;
}

sub dump {
  my ($self, $msg) = @_;

  $msg .= ';' unless $msg =~ /[,，！!。.]$/;

  if ($self->debug == 1) {
    say $self->now . " - [debug] $msg";
  }
  elsif ($self->debug > 1) {
    my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
    make_path($workdir) unless -d $workdir;

    my $filename = "$workdir/$self->{device}->{host}.txt";

    open(my $fh, '>>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
    my $text = $self->now . " - [debug] $msg\n";
    print $fh $text or croak "写入文件 $filename 失败: $!";
    close($fh)      or croak "关闭文件句柄 $filename 失败: $!";
  }
}

sub write_file {
  my ($self, $config, $name) = @_;

  croak("必须提供非空配置信息") unless !!$config;

  $name //= $self->{device}{host} . ".txt";

  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
  make_path($workdir) unless -d $workdir;

  $self->dump("准备将配置文件写入工作目录: ($workdir)");

  my $filename = "$workdir/$name";

  open(my $fh, '>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $config            or croak "写入文件 $filename 失败: $!";
  close($fh)                   or croak "关闭文件句柄 $filename 失败: $!";

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

  state $replacements = {
    'Ten-GigabitEthernet' => 'TE',
    'GigabitEthernet'     => 'GE',
    'Smartrate-Ethernet'  => 'SE',
    'Ethernet'            => 'Eth',
    'xethernet'           => 'XE',
    'ethernet'            => 'E',
    'xge'                 => 'TE',
    'ge'                  => 'G',
    'Twe'                 => 'TW',
    'eth'                 => 'Eth',
  };

  for my $pattern (keys %$replacements) {
    $name =~ s/$pattern/$replacements->{$pattern}/gi;
  }

  return $name;
}

1;
