package Parallel::Pipes;
use 5.008001;
use strict;
use warnings;
use IO::Handle;
use IO::Select;

use constant WIN32 => $^O eq 'MSWin32';

our $VERSION = '0.201';

{
    package Parallel::Pipes::Impl;
    use Storable ();
    sub new {
        my ($class, %option) = @_;
        my $read_fh  = delete $option{read_fh}  or die;
        my $write_fh = delete $option{write_fh} or die;
        $write_fh->autoflush(1);
        bless { %option, read_fh => $read_fh, write_fh => $write_fh, buf => '' }, $class;
    }
    sub read :method {
        my $self = shift;
        my $_size = $self->_read(4) or return;
        my $size = unpack 'I', $_size;
        my $freezed = $self->_read($size);
        Storable::thaw($freezed);
    }
    sub write :method {
        my ($self, $data) = @_;
        my $freezed = Storable::freeze({data => $data});
        my $size = pack 'I', length($freezed);
        $self->_write("$size$freezed");
    }
    sub _read {
        my ($self, $size) = @_;
        my $fh = $self->{read_fh};
        my $offset = length $self->{buf};
        while ($offset < $size) {
            my $len = sysread $fh, $self->{buf}, 65536, $offset;
            if (!defined $len) {
                die $!;
            } elsif ($len == 0) {
                last;
            } else {
                $offset += $len;
            }
        }
        return substr $self->{buf}, 0, $size, '';
    }
    sub _write {
        my ($self, $data) = @_;
        my $fh = $self->{write_fh};
        my $size = length $data;
        my $offset = 0;
        while ($size) {
            my $len = syswrite $fh, $data, $size, $offset;
            if (!defined $len) {
                die $!;
            } elsif ($len == 0) {
                last;
            } else {
                $size   -= $len;
                $offset += $len;
            }
        }
        $size;
    }
}
{
    package Parallel::Pipes::Here;
    our @ISA = qw(Parallel::Pipes::Impl);
    use Carp ();
    sub new {
        my ($class, %option) = @_;
        $class->SUPER::new(%option, _written => 0);
    }
    sub is_written {
        my $self = shift;
        $self->{_written} == 1;
    }
    sub read :method {
        my $self = shift;
        if (!$self->is_written) {
            Carp::croak("This pipe has not been written; you cannot read it");
        }
        $self->{_written}--;
        return unless my $read = $self->SUPER::read;
        $read->{data};
    }
    sub write :method {
        my ($self, $task) = @_;
        if ($self->is_written) {
            Carp::croak("This pipe has already been written; you must read it first");
        }
        $self->{_written}++;
        $self->SUPER::write($task);
    }
}
{
    package Parallel::Pipes::There;
    our @ISA = qw(Parallel::Pipes::Impl);
}
{
    package Parallel::Pipes::Impl::NoFork;
    use Carp ();
    sub new {
        my ($class, %option) = @_;
        bless {%option}, $class;
    }
    sub is_written {
        my $self = shift;
        exists $self->{_result};
    }
    sub read :method {
        my $self = shift;
        if (!$self->is_written) {
            Carp::croak("This pipe has not been written; you cannot read it");
        }
        delete $self->{_result};
    }
    sub write :method {
        my ($self, $task) = @_;
        if ($self->is_written) {
            Carp::croak("This pipe has already been written; you must read it first");
        }
        my $result = $self->{work}->($task);
        $self->{_result} = $result;
    }
}

sub new {
    my ($class, $number, $work, $option) = @_;
    if (WIN32 and $number != 1) {
        die "The number of pipes must be 1 under WIN32 environment.\n";
    }
    my $self = bless {
        work => $work,
        number => $number,
        no_fork => $number == 1,
        pipes => {},
        option => $option || {},
    }, $class;

    if ($self->no_fork) {
        $self->{pipes}{-1} = Parallel::Pipes::Impl::NoFork->new(pid => -1, work => $self->{work});
    } else {
        $self->_fork for 1 .. $number;
    }
    $self;
}

sub no_fork { shift->{no_fork} }

sub _fork {
    my $self = shift;
    my $work = $self->{work};
    pipe my $read_fh1, my $write_fh1;
    pipe my $read_fh2, my $write_fh2;
    my $pid = fork;
    die "fork failed" unless defined $pid;
    if ($pid == 0) {
        srand;
        close $_ for $read_fh1, $write_fh2, map { ($_->{read_fh}, $_->{write_fh}) } $self->pipes;
        my $there = Parallel::Pipes::There->new(read_fh  => $read_fh2, write_fh => $write_fh1);
        while (my $read = $there->read) {
            $there->write( $work->($read->{data}) );
        }
        exit;
    }
    close $_ for $write_fh1, $read_fh2;
    $self->{pipes}{$pid} = Parallel::Pipes::Here->new(
        pid => $pid, read_fh => $read_fh1, write_fh => $write_fh2,
    );
}

sub pipes {
    my $self = shift;
    map { $self->{pipes}{$_} } sort { $a <=> $b } keys %{$self->{pipes}};
}

sub is_ready {
    my $self = shift;
    return $self->pipes if $self->no_fork;

    my @pipes = @_ ? @_ : $self->pipes;
    if (my @ready = grep { $_->{_written} == 0 } @pipes) {
        return @ready;
    }

    my $select = IO::Select->new(map { $_->{read_fh} } @pipes);
    my @ready;
    if (my $tick = $self->{option}{idle_tick}) {
        while (1) {
            if (my @r = $select->can_read($tick)) {
                @ready = @r;
                last;
            }
            $self->{option}{idle_work}->();
        }
    } else {
        @ready = $select->can_read;
    }

    my @return;
    for my $pipe (@pipes) {
        if (grep { $pipe->{read_fh} == $_ } @ready) {
            push @return, $pipe;
        }
    }
    return @return;
}

sub is_written {
    my $self = shift;
    grep { $_->is_written } $self->pipes;
}

sub close :method {
    my $self = shift;
    return if $self->no_fork;

    close $_ for map { ($_->{write_fh}, $_->{read_fh}) } $self->pipes;
    while (%{$self->{pipes}}) {
        my $pid = wait;
        if (delete $self->{pipes}{$pid}) {
            # OK
        } else {
            warn "wait() unexpectedly returns $pid\n";
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Parallel::Pipes - parallel processing using pipe(2) for communication and synchronization

=head1 SYNOPSIS

  use Parallel::Pipes;

  my $pipes = Parallel::Pipes->new(5, sub {
    # this is a worker code
    my $task = shift;
    my $result = do_work($task);
    return $result;
  });

  my $queue = Your::TaskQueue->new;
  # wrap Your::TaskQueue->get
  my $get; $get = sub {
    my $queue = shift;
    if (my @task = $queue->get) {
      return @task;
    }
    if (my @written = $pipes->is_written) {
      my @ready = $pipes->is_ready(@written);
      $queue->register($_->read) for @ready;
      return $queue->$get;
    } else {
      return;
    }
  };

  while (my @task = $queue->$get) {
    my @ready = $pipes->is_ready;
    $queue->register($_->read) for grep $_->is_written, @ready;
    my $min = List::Util::min($#task, $#ready);
    for my $i (0..$min) {
      # write tasks to pipes which are ready
      $ready[$i]->write($task[$i]);
    }
  }

  $pipes->close;

=head1 DESCRIPTION

B<NOTE>: Parallel::Pipes provides low-level interfaces.
If you are interested in using Parallel::Pipes,
you may want to look at L<Parallel::Pipes::App> instead,
which provides more friendly interfaces.

Parallel processing is essential, but it is also difficult:

=over 4

=item How can we synchronize our workers?

More precisely, how to detect our workers are ready or finished.

=item How can we communicate with our workers?

More precisely, how to collect results of tasks.

=back

Parallel::Pipes tries to solve these problems with C<pipe(2)> and C<select(2)>.

L<App::cpm>, a fast CPAN module installer, uses Parallel::Pipes.
Please look at L<App::cpm|https://github.com/skaji/cpm/blob/master/lib/App/cpm/CLI.pm>
or L<eg directory|https://github.com/skaji/Parallel-Pipes/tree/main/eg> for real world usages.

=begin html

<a href="https://raw.githubusercontent.com/skaji/Parallel-Pipes/main/author/image.png"><img src="https://raw.githubusercontent.com/skaji/Parallel-Pipes/main/author/image.png" alt="image" class="img-responsive"></a>

=end html

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
