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

#------------------------------------------------------------------------------
# 并发执行脚本 - 入参为设备清单，为每台设备调度配置备份任务
#------------------------------------------------------------------------------
sub run {
  my $self = shift;

  # 根据负载量自动设定线程数
  @{$self->workers} > $self->thread ? $self->thread : $self->thread(scalar @{$self->workers});

  # 按照线程数塞进负载任务
  my $i = 0;
  my @threads;
  for my $job (@{$self->workers}) {
    push(@{$threads[$i % $self->thread]}, $job);
    $i++;
  }

  # fork 线程并发调度任务
  my %childPids;
  for (my $j = 0; $j < $self->thread; $j++) {
    if (my $pid = fork) {
      $childPids{$pid} = undef;
    }
    else {
      for my $work (@{$threads[$j]}) {
        eval { $self->handler()->($work) } or die "Can't handle $work: $@\n";
        sleep 0.5;
      }
      exit;
    }
    sleep 1;
  }

  # 异步非阻塞等待并发任务运行结束
  my $exitPid;
  while (keys(%childPids)) {
    while (($exitPid = waitpid(-1, WNOHANG)) > 0) {
      delete($childPids{$exitPid});
      sleep 0.5;
    }
  }

  return 1;
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
  use Parallel::Manager;

  sub callback {
    my $name = shift;
    say qq{callback $name #times};
  }

  my $p = Parallel::Manager->new(handler => \&callback, workers => [1 .. 100]);
  # will callback 100 times async

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

