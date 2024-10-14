package PDK::Device::ConfigBackup;

use v5.30;
use Moose;
use namespace::autoclean;

use Carp       qw(croak);
use POSIX      qw(WNOHANG strftime);
use File::Path qw(make_path);
use Parallel::ForkManager;
use Try::Tiny;
use Thread::Queue;


has now => (
  is      => 'ro',
  default => sub {
    my $time = `date "+%Y-%m-%d %H:%M:%S"`;
    chomp($time);
    return $time;
  },
);

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

has workdir => (is => 'rw', default => sub { $ENV{PDK_DEVICE_BACKUP_HOME} // glob("~") },);

has result => (
  is      => 'rw',
  default => sub {
    return {map { $_ => {success => [], fail => []} } qw(getConfig ftpConfig execCommands)};
  },
);

has debug => (is => 'rw', default => 0,);


sub dump {
  my ($self, $msg) = @_;

  $self->{debug} ||= $ENV{PDK_DEVICE_BACKUP_DEBUG};
  return unless $self->{debug};

  if ($self->{debug} == 1) {
    say "[debug] $msg;";
  }
  elsif ($self->{debug} > 1) {
    my $workdir = "$self->{workdir}/dump/$self->{month}/$self->{date}";
    make_path($workdir) unless -d $workdir;

    my $filename = "$workdir/dump_log.txt";
    open(my $fh, '>>', $filename)            or croak "无法打开文件 $filename 进行写入: $!";
    say $fh $self->now . " - [debug] $msg ;" or croak "写入文件 $filename 失败: $!";
    close($fh)                               or croak "关闭文件句柄 $filename 失败: $!";
  }
}

sub initPdkDevice {
  my ($self, $param) = @_;

  my $username = $param->{username} || $ENV{PDK_DEVICE_USERNAME};
  my $password = $param->{password} || $ENV{PDK_DEVICE_PASSWORD};
  my $host     = $param->{ip};

  croak "必须提供设备登录(IP)所需账户密码或设置相关的环境变量：PDK_DEVICE_USERNAME，PDK_DEVICE_PASSWORD;"
    unless ($username && $password && $host);

  my $class = $param->{pdk_device_module};
  eval "use $class; 1" or die "加载模块失败: $class";

  $self->dump("尝试自动加载模块并初始化对象($param->{name}/$host)：$class");
  my $device = $class->new(host => $host, username => $username, password => $password) or die "实例化模块失败: $class";

  return $device;
}

sub assignAttributes {
  my ($self, $items) = @_;

  croak "必须提供基于哈希对象的数组引用" if ref($items) ne 'ARRAY';

  my %os_to_module = (
    qr/^Cisco|ios/i   => 'PDK::Device::Cisco',
    qr/^nx-os/i       => 'PDK::Device::Cisco::Nxos',
    qr/^PAN-OS/i      => 'PDK::Device::Paloalto',
    qr/^Radware/i     => 'PDK::Device::Radware',
    qr/^H3C|Comware/i => 'PDK::Device::H3c',
    qr/^Hillstone/i   => 'PDK::Device::Hillstone',
    qr/^junos/i       => 'PDK::Device::Juniper',
  );

  for my $item (@$items) {
    croak "设备属性必须包含 'ip' 和 'name' 属性" unless exists $item->{ip} && exists $item->{name};

    $item->{username} ||= $ENV{PDK_DEVICE_USERNAME};
    $item->{password} ||= $ENV{PDK_DEVICE_PASSWORD};

    my ($module) = grep { $item->{os} =~ $_ } keys %os_to_module;
    croak "暂不兼容的 OS：$item->{os}" unless !!$module;
    $item->{pdk_device_module} = $os_to_module{$module};
    $item->{name} =~ s/\..*$//;
  }
  $self->dump("尝试自动装配 {pdk_device_module} 并修正设备主机名");

  return $items;
}

sub getConfigJob {
  my ($self, $devices) = @_;

  try {
    $devices = $self->assignAttributes($devices);
    my $count = scalar(@{$devices});
    $self->dump("开始任务：并行执行 ($count) 台设备的配置获取任务");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $status = $self->startGetConfig($device);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{getConfig};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置备份${flag}_设备清单");
    }
  }
}

sub ftpConfigJob {
  my ($self, $devices) = @_;

  try {
    $devices = $self->assignAttributes($devices);
    my $count = scalar(@{$devices});
    $self->dump("开始任务：并行执行 ($count) 台设备的配置获取任务");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $status = $self->startFtpConfig($device);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{ftpConfig};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "FTP备份${flag}_设备清单");
    }
  }
}

sub execCommandsJob {
  my ($self, $devices, $commands) = @_;

  try {
    $devices = $self->assignAttributes($devices);
    my $count = scalar(@{$devices});
    $self->dump("开始任务：并行执行 ($count) 台设备的配置下发任务，各设备推送的脚本一致");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $status = $self->startExecCommands($device, $commands);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{execCommands};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置下发${flag}_设备清单");
    }
  }
}

sub runCommandsJob {
  my ($self, $devices) = @_;

  foreach my $device (@{$devices}) {
    if (!$device->{commands} || @{$device->{commands}} == 0) {
      $self->dump("[runCommandsJob/前置检查阶段]：所有设备的命令列表都不能为空");
      die "设备 " . $device->{name} . " 的命令列表为空";
    }
  }

  try {
    $devices = $self->assignAttributes($devices);
    my $count = scalar(@{$devices});
    $self->dump("开始任务：并行执行 ($count) 台设备的配置下发任务，推送的脚本各自独立");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $commands = $device->{commands};
    my $status   = $self->startExecCommands($device, $commands);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{execCommands};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置下发${flag}_设备清单");
    }
  }
}

sub ftpConfig {
  my ($self, $param) = @_;
  $self->dump("开始任务：对设备($param->{name}/$param->{ip})执行 FTP 备份操作");

  try {
    my $device     = $self->initPdkDevice($param);
    my $hostname   = $param->{name};
    my $ftp_server = $param->{ftp_server} // $ENV{PDK_FTP_SERVER};

    croak "启用 FTP 备份配置，必须正确配置 FTP 服务器地址和设备名称" unless $ftp_server && $hostname;

    $device->ftpConfig($hostname, $ftp_server);
    return {success => 1};
  }
  catch {
    return {success => 0, reason => $_};
  };
}

sub getConfig {
  my ($self, $param) = @_;
  $self->dump("开始任务：对设备($param->{name}/$param->{ip})执行配置获取操作");

  try {
    my $device = $self->initPdkDevice($param);
    return $device->getConfig();
  }
  catch {
    return {success => 0, reason => $_};
  };
}

sub execCommands {
  my ($self, $param, $commands) = @_;
  $self->dump("开始任务：对设备($param->{name}/$param->{ip})执行命令下发操作");

  try {
    my $device = $self->initPdkDevice($param);
    return $device->execCommands($commands);
  }
  catch {
    return {success => 0, reason => $_};
  };
}

sub startFtpConfig {
  my ($self, $param) = @_;
  $self->dump("激活任务：对设备($param->{name}/$param->{ip})执行 FTP 备份并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->ftpConfig($param);
  my $status = $self->{result}{ftpConfig};
  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) FTP 备份成功";
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) FTP 备份失败: $result->{reason}";
  }

  return $status;
}

sub startExecCommands {
  my ($self, $param, $commands) = @_;
  $self->dump("激活任务：对设备($param->{name}/$param->{ip})命令下发并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->execCommands($param, $commands);
  my $status = $self->{result}{execCommands};
  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) 配置下发成功";
    my $filename = "${name}_${ip}_execCommands.cfg";
    $self->write_file($result->{result}, $filename);
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) 配置下发失败: $result->{reason}";
  }

  return $status;
}

sub startGetConfig {
  my ($self, $param) = @_;
  $self->dump("激活任务：对设备($param->{name}/$param->{ip})配置获取并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->getConfig($param);
  my $status = $self->{result}{getConfig};
  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) 配置备份成功";
    my $filename = "${name}_${ip}_getConfig.cfg";
    $self->write_file($result->{config}, $filename);
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) 配置备份失败: $result->{reason}";
  }

  return $status;
}

sub write_file {
  my ($self, $content, $filename) = @_;

  croak("请正确设置需要保存的内容和文件名") unless $content && $filename;

  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
  make_path($workdir) unless -d $workdir;

  $self->dump("准备将配置文件写入工作目录: ($workdir)");

  $filename = "$workdir/$filename";

  open(my $fh, '>>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $content            or croak "写入文件 $filename 失败: $!";
  close($fh)                    or croak "关闭文件句柄 $filename 失败: $!";

  $self->dump("已将配置文件写入文本文件: $filename");

  return {success => 1};
}

__PACKAGE__->meta->make_immutable;
1;
