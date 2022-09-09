package Parallel::Manager;

# ABSTRACT: fork threads to run some callback together
#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use POSIX qw/WNOHANG/;

#------------------------------------------------------------------------------
# 定义模块通用方法和属性
#------------------------------------------------------------------------------
has handler => (is => 'rw', isa => 'CodeRef', required => 1,);

has workers => (is => 'ro', isa => 'ArrayRef', required => 1,);

has thread => (is => 'rw', isa => 'Int', default => 5,);

# 等待子进程以及进入下一个子进程的周期
has poll_interval => (is => 'rw', isa => 'Num', default => 0.5,);

# 进入下一个队列的周期
has wait_interval => (is => 'rw', isa => 'Num', default => 0.5,);

#------------------------------------------------------------------------------
# 开启并发调度任务
#------------------------------------------------------------------------------
sub run {
  my $self = shift;

  # 根据负载量自动设定线程数
  @{$self->workers} > $self->thread ? $self->thread : $self->thread(scalar @{$self->workers});

  # 按照线程数塞进负载任务，拆分成 $self->thread 个子队列
  my $i = 0;
  my @threads;
  for my $job (@{$self->workers}) {
    push(@{$threads[$i % $self->thread]}, $job);
    $i++;
  }

  # 切入运行前钩子函数
  if ($self->{before_run_code}) {
    $self->{before_run_code}->($self->{before_run_vars});
  }

  # fork 线程并发调度任务
  my %childPids;
  for (my $j = 0; $j < $self->thread; $j++) {
    if (my $pid = fork) {
      $childPids{$pid} = undef;
    }
    else {
      for my $work (@{$threads[$j]}) {
        if ($self->{before_job_run_code}) {
          $self->{before_job_run_code}->($self->{before_job_run_vars});
        }
        eval { $self->handler->($work) } or die "Can't handle $work: $@\n";
        if ($self->{after_job_run_code}) {
          $self->{after_job_run_code}->($self->{after_job_run_vars});
        }
        sleep $self->poll_interval;
      }
      exit;
    }
    sleep $self->wait_interval;
  }

  # 异步非阻塞等待并发任务运行结束
  my $exitPid;
  while (keys(%childPids)) {
    while (($exitPid = waitpid(-1, WNOHANG)) > 0) {
      delete($childPids{$exitPid});
      sleep $self->wait_interval;
    }
  }

  # 运行结束后钩子函数
  if ($self->{after_run_code}) {
    $self->{after_run_code}->($self->{after_run_vars});
  }

  return 1;
}

#------------------------------------------------------------------------------
# 获取当前调用的函数名称
#------------------------------------------------------------------------------
sub called_subroutine {
  '[split(/::/, (caller(0))[3])]->[-1];';
}

#------------------------------------------------------------------------------
# 设定回调函数
#------------------------------------------------------------------------------
sub set_callback_name {
  my ($self, $name, $code, $vars) = @_;
  if (ref $code eq 'CODE') {
    $self->{$name . '_code'} = $code;
    $self->{$name . '_vars'} = $vars;
  }
  else {
    die "Must set callback code";
  }
}

#------------------------------------------------------------------------------
# RUN 函数运行前钩子函数
#------------------------------------------------------------------------------
sub before_run {
  my ($self, $code, $vars) = @_;
  $self->set_callback_name("before_run", $code, $vars);
}

#------------------------------------------------------------------------------
# RUN 函数运行后钩子函数
#------------------------------------------------------------------------------
sub after_run {
  my ($self, $code, $vars) = @_;
  $self->set_callback_name("after_run", $code, $vars);
}

#------------------------------------------------------------------------------
# 子任务运行前钩子函数
#------------------------------------------------------------------------------
sub before_job_run {
  my ($self, $code, $vars) = @_;
  $self->set_callback_name("before_job_run", $code, $vars);
}

#------------------------------------------------------------------------------
# 子任务运行后钩子函数
#------------------------------------------------------------------------------
sub after_job_run {
  my ($self, $code, $vars) = @_;
  $self->set_callback_name("after_job_run", $code, $vars);
}

#------------------------------------------------------------------------------
# 支持哈希或标量实例化对象
#------------------------------------------------------------------------------
sub BUILDARGS {
  my $self  = shift;
  my %param = (@_ > 0 and ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  return \%param;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parallel::Manager

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use 5.018;
  use Data::Printer;
  use Parallel::Manager;

  sub callback {
    my $name = shift;
    say qq{callback $name #times};
  }

  # handler and workers must defined, other attributes have default value;
  my $pm = Parallel::Manager->new(handler => \&callback, workers => [1 .. 100], thread => 10, poll_interval => 0.2, wait_interval => 0.5);

  # you can define some callback when $pm->run

  $p->before_run(\&callback, "python");
  $p->after_run(\&callback, "perl");
  $p->before_job_run(\&callback, "php");
  $p->after_job_run(\&callback, "ruby");

  $pm->run;  # will callback 100 times async

  # use DDP to see more info
  p $pm;

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/ciscolive/Parallel-Manager/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/ciscolive/Parallel-Manager>

  git clone git://github.com/ciscolive/Parallel-Manager.git

=head1 AUTHOR

WENWU YAN <careline@cpan.org>

=head1 CONTRIBUTOR

WENWU YAN  <careline@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by WENWU YAN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

