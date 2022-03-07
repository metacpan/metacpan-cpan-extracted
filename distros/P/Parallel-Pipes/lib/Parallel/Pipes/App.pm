package Parallel::Pipes::App;
use strict;
use warnings;

use Parallel::Pipes;

our $VERSION = '0.102';

sub _min { $_[0] < $_[1] ? $_[0] : $_[1] }

sub run {
    my ($class, %argv) = @_;

    my $work = $argv{work} or die "need 'work' argument\n";
    my $num = $argv{num} or die "need 'num' argument\n";
    my $tasks = $argv{tasks} or die "need 'tasks' argument\n";
    my $before_work = $argv{before_work};
    my $after_work = $argv{after_work};

    my $pipes = Parallel::Pipes->new($num, $work);
    while (1) {
        my @ready = $pipes->is_ready;
        if (my @written = grep { $_->is_written } @ready) {
            for my $written (@written) {
                my $result = $written->read;
                $after_work->($result) if $after_work;
            }
        }
        if (@$tasks) {
            my $min = _min $#{$tasks}, $#ready;
            for my $i (0 .. $min) {
                my $task = shift @$tasks;
                $before_work->($task) if $before_work;
                $ready[$i]->write($task);
            }
        } else {
            if (@ready == $num) {
                last;
            } else {
                if (my @written = $pipes->is_written) {
                    my @ready = $pipes->is_ready(@written);
                    for my $written (@ready) {
                        my $result = $written->read;
                        $after_work->($result) if $after_work;
                    }
                } else {
                    die "unexpected";
                }
            }
        }
    }
    $pipes->close;
    1;
}

sub map :method {
    my ($class, %argv) = @_;

    my $orig_num = $argv{num} or die "need 'num' argument\n";
    my $orig_tasks = $argv{tasks} or die "need 'tasks' argument\n";
    my $orig_work = $argv{work} or die "need 'work' argument\n";

    my @task = map { [$_, $orig_tasks->[$_]] } 0..$#{$orig_tasks};
    my $work = sub {
        my ($index, $task) = @{$_[0]};
        my $result = $orig_work->($task);
        [$index, $result];
    };
    my @result;
    my $after_work = sub {
        my ($index, $result) = @{$_[0]};
        $result[$index] = $result;
    };
    $class->run(num => $orig_num, work => $work, tasks => \@task, after_work => $after_work);
    @result;
}

1;
__END__

=head1 NAME

Parallel::Pipes::App - friendly interface for Parallel::Pipes

=head1 SYNOPSIS

  use Parallel::Pipes::App;

  my @result = Parallel::Pipes::App->map(
    num => 3,
    work => sub { my $task = shift; $task * 2 },
    tasks => [1, 2, 3, 4, 5],
  );
  # @result is ( 2, 4, 6, 8, 10 )

=head1 DESCRIPTION

Parallel::Pipes::App provides friendly interfaces for L<Parallel::Pipes>.

=head1 METHODS

Parallel::Pipes::App provides 2 class method:

=head2 map

  my @result = Parallel::Pipes::App->map(
    num => $num,
    work => $work,
    tasks => \@task,
  );

Process C<@task> by C<$work> in C<$num> pre-forked child processes, and get C<@result>.
This is almost the same as

  my @result = map { $work->($_) } @task;

except that C<$work> is executed in a child process, not in the current process.

=head2 run

  Parallel::Pipes::App->run(
    num => $num,
    work => $work,
    tasks => \@task,
    before_work => $before_work,
    after_work => $after_work,
  );

C<run> is a more generic form of C<map>. In fact, we can write C<map> by using C<run>:

  my @result;
  Parallel::Pipes::App->run(
    num => $num,
    work => $work,
    tasks => \@task,
    before_work => sub {},
    after_work => sub { push @result, $_[0] },
  );

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
