package PDK::Device::ConfigBackup;

use utf8;
use v5.30;
use Moose;
use Carp       qw(croak);
use File::Path qw(make_path);
use Data::Dumper;
use Parallel::ForkManager;
use Thread::Queue;
use namespace::autoclean;

with 'PDK::Device::Concern::Dumper';


has queue => (
  is      => 'rw',
  default => sub {
    my $value = $ENV{PDK_DEVICE_BACKUP_QUEUE};
    PDK::Device::Concern::Dumper::_debug_init("从环境变量中加载并设置 queue：($value)") if defined $value;
    return $value // 10;
  },
);

has workdir => (
  is      => 'rw',
  default => sub {
    my $value = $ENV{PDK_DEVICE_BACKUP_HOME};
    PDK::Device::Concern::Dumper::_debug_init("从环境变量中加载并设置 workdir：($value)") if defined $value;
    return $value // glob("~");
  },
);

has debug => (
  is      => 'rw',
  default => sub {
    my $value = $ENV{PDK_DEVICE_BACKUP_DEBUG};
    PDK::Device::Concern::Dumper::_debug_init("从环境变量中加载并设置 debug：($value)") if defined $value;
    return $value // 0;
  },
);

has result => (
  is      => 'rw',
  default => sub {
    return {map { $_ => {success => [], fail => []} } qw(getConfig ftpConfig execCommands)};
  },
);

sub getConfigJob {
  my ($self, @args) = @_;

  my @devices = @args == 1 && ref $args[0] eq 'ARRAY' ? @{$args[0]} : @args;

  eval {
    @devices = $self->assignPdkModules(@devices);
    my $count = scalar(@devices);
    $self->dump("[getConfigJob] 开始配置备份任务：并行执行 ($count) 台设备的配置获取任务");
  };
  if (!!$@) {
    croak "[getConfigJob] 自动加载并装配模块抛出异常: $@";
  }

  my $pm    = Parallel::ForkManager->new($self->{queue});
  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;
    $queue->enqueue($data) if defined $data;
  });

  foreach my $device (@devices) {
    $self->dump("[getConfigJob] 开始子任务：发起设备 ($device->{name}/$device->{ip}) 配置备份任务");
    $pm->start and next;
    my $status = $self->startGetConfig($device);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{getConfig};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }
  $self->dump("[getConfigJob] 配置备份任务执行完毕，正在将运行结果写入日志文件中");

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置备份${flag}_设备清单.txt");
    }
  }
}

sub ftpConfigJob {
  my ($self, @args) = @_;

  my @devices = @args == 1 && ref $args[0] eq 'ARRAY' ? @{$args[0]} : @args;

  eval {
    @devices = $self->assignPdkModules(@devices);
    my $count = scalar(@devices);
    $self->dump("[ftpConfigJob] 开始FTP配置备份任务：并行执行 ($count) 台设备的配置获取任务");
  };
  if (!!$@) {
    croak "[ftpConfigJob] 自动加载并装配模块抛出异常: $@";
  }

  my $pm    = Parallel::ForkManager->new($self->{queue});
  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;
    $queue->enqueue($data) if defined $data;
  });

  foreach my $device (@devices) {
    $self->dump("[ftpConfigJob] 开始子任务：发起设备 ($device->{name}/$device->{ip}) FTP配置备份任务");
    $pm->start and next;
    my $status = $self->startFtpConfig($device);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{ftpConfig};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }
  $self->dump("[ftpConfigJob] FTP配置备份任务执行完毕，正在将运行结果写入日志文件中");

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "FTP备份${flag}_设备清单.txt");
    }
  }
}

sub execCommandsJob {
  my ($self, $commands, @args) = @_;

  my @devices = @args == 1 && ref $args[0] eq 'ARRAY' ? @{$args[0]} : @args;

  eval {
    @devices = $self->assignPdkModules(@devices);
    my $count = scalar(@devices);
    $self->dump("[execCommandsJob] 开始任务：并行执行 ($count) 台设备的配置下发任务，各设备推送的脚本一致");
  };
  if (!!$@) {
    croak "[execCommandsJob] 自动加载并装配模块抛出异常: $@";
  }

  my $pm    = Parallel::ForkManager->new($self->{queue});
  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;
    $queue->enqueue($data) if defined $data;
  });

  foreach my $device (@devices) {
    $self->dump("[execCommandsJob] 开始子任务：发起设备 ($device->{name}/$device->{ip}) 脚本自动下发任务");
    $pm->start and next;
    my $status = $self->startExecCommands($device, $commands);
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = $self->{result}{execCommands};
  while (my $data = $queue->dequeue_nb()) {
    push @{$result->{$_}}, @{$data->{$_}} for qw(success fail);
  }
  $self->dump("[execCommandsJob] 脚本自动下发任务执行完毕，正在将运行结果写入日志文件中");

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置下发${flag}_设备清单.txt");
    }
  }
}

sub runCommandsJob {
  my ($self, @args) = @_;

  my @devices = @args == 1 && ref $args[0] eq 'ARRAY' ? @{$args[0]} : @args;
  my @actives = ();

  foreach my $device (@devices) {
    if (!$device->{commands} || @{$device->{commands}} == 0) {
      $self->dump("[runCommandsJob/前置检查阶段]：设备 ($device->{name}/$device->{ip}) 配置下发列表不能为空，将自动跳过");
    }
    else {
      push @actives, $device;
      $self->dump("[runCommandsJob/前置检查阶段]：设备 ($device->{name}/$device->{ip}) 包含下发配置列表，符合配置自动下发规则");
    }
  }

  eval {
    @actives = $self->assignPdkModules(@actives);
    my $count = scalar(@actives);
    $self->dump("[runCommandsJob] 开始配置推送任务：并行执行 ($count) 台设备的配置下发任务，推送的脚本各自独立");
  };
  if (!!$@) {
    croak "[runCommandsJob] 自动加载并装配模块抛出异常: $@";
  }

  my $pm    = Parallel::ForkManager->new(10);
  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;
    $queue->enqueue($data) if defined $data;
  });

  foreach my $device (@actives) {
    $self->dump("[runCommandsJob] 开始子任务：发起设备 ($device->{name}/$device->{ip}) 脚本自动下发(高权模式)任务");
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
  $self->dump("[runCommandsJob] 脚本自动下发(高权模式)任务执行完毕，正在将运行结果写入日志文件中");

  for my $type (qw(success fail)) {
    if (@{$result->{$type}}) {
      my $text = join("\n", @{$result->{$type}});
      my $flag = $type eq 'success' ? '成功' : '失败';
      $self->write_file($text, "配置下发${flag}_设备清单.txt");
    }
  }
}

sub ftpConfig {
  my ($self, $param) = @_;
  $self->dump("[ftpConfig] 开始FTP配置备份任务：对设备($param->{name}/$param->{ip})执行 FTP 备份操作");

  my $result;
  eval {
    my $hostname   = $param->{name};
    my $ftp_server = $param->{ftp_server} // $ENV{PDK_FTP_SERVER};

    croak "[ftpConfig] 启用 FTP 备份配置，必须正确配置 FTP 服务器地址和设备名称" unless $ftp_server && $hostname;

    my $device = $self->initPdkDevice($param);

    $device->ftpConfig($hostname, $ftp_server);
    $result = {success => 1};
  };
  if (!!$@) {
    $result = {success => 0, reason => $@};
  }

  return $result;
}

sub getConfig {
  my ($self, $param) = @_;
  $self->dump("[getConfig] 开始配置备份任务：对设备($param->{name}/$param->{ip})执行配置获取操作");

  my $result;
  eval {
    my $device = $self->initPdkDevice($param);
    $result = $device->getConfig();
  };
  if (!!$@) {
    $result = {success => 0, reason => $@};
  }

  return $result;
}

sub execCommands {
  my ($self, $param, $commands) = @_;
  $self->dump("[execCommands] 开始配置下发任务：对设备($param->{name}/$param->{ip})执行命令下发操作");

  my $result;
  eval {
    my $device = $self->initPdkDevice($param);
    $result = $device->execCommands($commands);
  };
  if (!!$@) {
    $result = {success => 0, reason => $@};
  }

  return $result;
}

sub startFtpConfig {
  my ($self, $param) = @_;
  $self->dump("[startFtpConfig] 激活FTP备份成功任务：对设备($param->{name}/$param->{ip})执行 FTP 备份并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->ftpConfig($param);
  my $status = $self->{result}{ftpConfig};

  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) FTP 备份成功";
    $self->dump("[startFtpConfig] FTP备份成功：设备 $name($ip) FTP 备份成功");
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) FTP 备份失败: $result->{reason}";
    $self->dump("[startFtpConfig] FTP备份失败：设备 $name($ip) FTP 备份异常: $result->{reason}");
  }

  return $status;
}

sub startExecCommands {
  my ($self, $param, $commands) = @_;
  $self->dump("[startExecCommands] 激活配置下发任务：对设备($param->{name}/$param->{ip})命令下发并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->execCommands($param, $commands);
  my $status = $self->{result}{execCommands};

  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) 配置下发成功";
    my $filename = "${name}_${ip}_execCommands.txt";
    $self->write_file($result->{result}, $filename);
    $self->dump("[startExecCommands] 配置下发成功：设备 $name($ip) 配置下发成功，快照保存在文件 $filename");
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) 配置下发失败: $result->{reason}";
    $self->dump("[startExecCommands] 配置下发失败：设备 $name($ip) 配置下发异常: $result->{reason}");
  }

  return $status;
}

sub startGetConfig {
  my ($self, $param) = @_;

  $self->dump("[startGetConfig] 激活配置备份任务：对设备($param->{name}/$param->{ip})配置获取并记录结果");

  my $name = $param->{name};
  my $ip   = $param->{ip};

  my $result = $self->getConfig($param);
  my $status = $self->{result}{getConfig};

  if ($result->{success}) {
    push @{$status->{success}}, $self->now . " - 设备 $name($ip) 配置备份成功";
    my $filename = "${name}_${ip}_getConfig.txt";
    $self->write_file($result->{config}, $filename);
    $self->dump("[startGetConfig] 配置备份成功：设备 $name($ip) 配置备份成功，快照保存在文件 $filename");
  }
  else {
    push @{$status->{fail}}, $self->now . " - 设备 $name($ip) 配置备份失败: $result->{reason}";
    $self->dump("[startGetConfig] 配置备份失败：设备 $name($ip) 配置备份任务异常: $result->{reason}");
  }

  return $status;
}

sub dump {
  my ($self, $msg) = @_;

  $msg .= ';' unless $msg =~ /^\s*$/ || $msg =~ /[,，！!。.]$/;

  my $text = $self->now() . " - [debug] $msg";
  if ($self->debug == 1) {
    say $text;
  }
  elsif ($self->debug > 1) {
    my $basedir = $ENV{PDK_DEVICE_HOME} // glob("~");
    my $workdir = "$basedir/dump/$self->{month}/$self->{date}";
    make_path($workdir) unless -d $workdir;

    my $filename = "$workdir/backup_dump.txt";
    open(my $fh, '>>encoding(UTF-8)', $filename) or croak "无法打开文件 $filename 进行写入: $!";
    print $fh "$text\n"                          or croak "写入文件 $filename 失败: $!";
    close($fh)                                   or croak "关闭文件句柄 $filename 失败: $!";
  }
}

__PACKAGE__->meta->make_immutable;
1;
