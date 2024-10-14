package PDK::Device::Radware;

use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
use namespace::autoclean;

with 'PDK::Device::Base';

has prompt => (is => 'ro', required => 1, default => '^>>.*?#\s*$',);

sub errCodes {
  my $self = shift;

  return [qr/^Error:.*?$/m,];
}

sub waitfor {
  my ($self, $prompt) = @_;

  my $buff = "";
  $prompt //= $self->{prompt};

  my $exp = $self->{exp};

  my @ret = $exp->expect(
    15,
    [
      qr/Confirm saving without first applying changes/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Confirm saving to FLASH/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Confirm dumping all information/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Display|Include) private keys/i => sub {
        my $passphrase = $self->{passphrase} || $ENV{PDK_FTP_PASSPHRASE};
        $self->{passphrase} = $passphrase if $self->{passphrase} ne $passphrase;

        $self->send(!!$passphrase ? "y\r" : "n\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Enter|Reconfirm) passphrase/i => sub {
        $self->send("$self->{passphrase}\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/$prompt/mi => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ],
    [
      eof => sub {
        croak("执行[waitfor]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[waitfor]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;

  return $buff;
}

sub runCommands {
  my ($self, $commands) = @_;

  croak "执行[runCommands]，必须提供一组待下发脚本" unless ref $commands eq 'ARRAY';

  unshift @$commands, 'cd' unless $commands->[0] =~ /^cd/mi;

  push @$commands, 'apply', 'save' unless $commands->[-1] =~ /^(apply|save)/mi;

  $self->execCommands($commands);
}

sub getConfig {
  my $self = shift;

  my $commands = ["cfg/dump", "cd",];

  my $config = $self->execCommands($commands);

  return $config if $config->{success} == 0;

  my $lines = $config->{result};

  return {success => 1, config => $lines};
}

sub ftpConfig {
  my ($self, $hostname, $server, $username, $password) = @_;

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  $server   //= $ENV{PDK_FTP_SERVER};
  $username //= $ENV{PDK_FTP_USERNAME};
  $password //= $ENV{PDK_FTP_PASSWORD};

  croak "请正确提供 FTP 服务器地址、账户和密码!" unless $username and $password and $server;

  my $passphrase = $self->{passphrase} || $ENV{PDK_FTP_PASSPHRASE} || $self->{$password};

  my $host    = $self->{host};
  my $command = "$self->{month}/$self->{date}/";

  if (!!$hostname) {
    $command .= "${hostname}_$host.tar.gz";
  }
  else {
    $command .= "$host.tar.gz";
  }

  my $exp    = $self->{exp};
  my $result = $exp ? ($exp->match() || '') : '';

  my $connector = "cfg/ptcfg ${server} -m -mansync";
  $self->dump("执行FTP备份脚本[$connector]，备份到目标文件为 $command");

  $self->send("$connector\n");
  my @ret = $exp->expect(
    15,
    [
      qr/hit return for automatic file name/i => sub {
        $result .= $exp->before() . $exp->match();
        $self->send("$command\r");
        exp_continue;
      }
    ],
    [
      qr/Enter username for FTP/i => sub {
        $self->send("$username\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Enter password for username/i => sub {
        $self->send("$password\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Display|Include) private keys/i => sub {
        $self->send($passphrase ? "y\r" : "n\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Enter|Reconfirm) passphrase/i => sub {
        $self->send("$passphrase\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/hit return for FTP server/i => sub {
        $result .= $exp->before() . $exp->match();
        $self->send("\r");
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    10,
    [
      qr/^Error: Illegal operation/mi => sub {
        croak("FTP 会话丢失: username or password is wrong!");
      }
    ],
    [
      qr/Current config successfully transferred/ => sub {
        $result .= $exp->before() . $exp->match();
        $self->dump("FTP 配置备份：文件 $command 上传成功");
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];
  $self->send("cd\r");

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;

1;
