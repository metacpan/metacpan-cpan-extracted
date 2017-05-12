package Process::Pipeline;
use 5.008001;
use strict;
use warnings;

use File::Temp ();

our $VERSION = '0.04';

{
    package Process::Pipeline::Process;
    my %SUPPORT_SET = map { $_ => 1 } qw(<  >  >>  2>  2>>  2>&1);
    sub new {
        my $class = shift;
        bless { cmd => [], set => {} }, $class;
    }
    sub cmd {
        my ($self, @arg) = @_;
        if (@arg) {
            if (ref $arg[0] eq 'CODE') {
                $self->{cmd} = $arg[0];
            } else {
                $self->{cmd} = \@arg;
            }
        }
        $self->{cmd};
    }
    sub set {
        my ($self, $key, $value) = @_;
        if ($key) {
            die "Unsupport set '$key'" unless $SUPPORT_SET{$key};
            $self->{set}{$key} = $value;
        }
        $self->{set};
    }
}

{
    package Process::Pipeline::Result::Each;
    sub new { my ($class, %option) = @_; bless {%option}, $class }
    sub status { shift->{status} }
    sub cmd    { shift->{cmd} }
    sub pid    { shift->{pid} }
}

{
    package Process::Pipeline::Result;
    use POSIX ();
    use Process::Status;
    use overload '@{}' => sub { shift->{result} };

    sub new {
        my $class = shift;
        bless {result => [], fh => undef}, $class;
    }
    sub push :method {
        my ($self, $hash) = @_;
        push @$self, $hash;
        $self;
    }
    sub is_success {
        my $self = shift;
        @$self == grep { $_->status->is_success } @$self;
    }
    sub fh {
        my $self = shift;
        $self->{fh} = shift if @_;
        $self->{fh};
    }
    sub wait :method {
        my $self = shift;
        while (grep { !defined $_->status } @$self) {
            my $pid = waitpid -1, POSIX::WNOHANG();
            my $save = $?;
            if ($pid == 0) {
                select undef, undef, undef, 0.01;
            } elsif ($pid == -1) {
                last;
            } else {
                my ($found) = grep { $_->pid == $pid } @$self;
                if (!$found) {
                    warn "waitpid returns $pid, but is not our child!";
                    last;
                }
                $found->{status} = Process::Status->new($save);
            }
        }
        if (my $filename = delete $self->{_filename}) {
            local $!;
            unlink $filename;
        }
        $self;
    }
}

sub new {
    bless { process => [] }, shift;
}

sub push :method {
    my ($self, $callback) = @_;
    my $p = Process::Pipeline::Process->new;
    $callback->($p);
    $self->_push($p);
}

sub _push {
    my ($self, $p) = @_;
    push @{$self->{process}}, $p;
    $self;
}

sub start {
    my ($self, %option) = @_;
    my $n = $#{$self->{process}};
    my @pipe = map { pipe my $read, my $write; [$read, $write] } 0..($n - 1);
    my $close = sub {
        my $i = shift;
        my @close = map { @{$pipe[$_]} } grep { $_ != $i - 1 && $_ != $i } 0..$#pipe;
        $_->close for @close;
    };

    my ($main_out_fh, $main_out_filename);
    my $result = Process::Pipeline::Result->new;
    for my $i (0..$n) {
        my $process = $self->{process}[$i];
        if ($i == $n && !$process->set->{">"} && !$process->set->{">>"}) {
            ($main_out_fh, $main_out_filename) = File::Temp::tempfile(UNLINK => 0);
        }
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            if ($main_out_filename) {
                close $main_out_fh;
                open STDOUT, ">>", $main_out_filename or die $!;
            }
            $close->($i);
            my $read  = $i - 1 >= 0 ? $pipe[$i - 1] : undef;
            my $write = $pipe[$i];
            if ($read) {
                $read->[1]->close;
                open STDIN, "<&", $read->[0];
                $read->[0]->close;
            }
            if ($write) {
                $write->[0]->close;
                open STDOUT, ">&", $write->[1];
                $write->[1]->close;
            }

            my %set = %{$process->set};
            if (my $in = $set{"<"}) {
                open STDIN, "<", $in or die "open $in: $!";
            }
            if (my $out = $set{">"} or my $append = $set{">>"}) {
                my $mode = defined $out ? ">"  : ">>";
                my $file = defined $out ? $out : $append;
                open STDOUT, $mode, $file or die "open $file: $!";
            }
            if (my $out = $set{"2>"} or my $append = $set{"2>>"}) {
                my $mode = defined $out ? ">"  : ">>";
                my $file = defined $out ? $out : $append;
                open STDERR, $mode, $file or die "open $file: $!";
            }
            if (exists $set{"2>&1"}) {
                open STDERR, ">&", \*STDOUT;
            }
            STDOUT->autoflush(1);

            my $cmd = $process->cmd;
            if (ref $cmd eq "CODE") {
                $cmd->();
                exit;
            } else {
                my @cmd = @$cmd;
                exec {$cmd[0]} @cmd;
                exit 255;
            }
        }
        $result->push(Process::Pipeline::Result::Each->new(
            pid => $pid,
            cmd => $process->cmd,
            status  => undef,
        ));
    }
    $_->close for map { @$_ } @pipe;
    if ($main_out_filename) {
        $result->{_filename} = $main_out_filename;
        $result->fh($main_out_fh);
    }
    $result->wait unless $option{async};
    $result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Process::Pipeline - execute processes as pipeline

=head1 SYNOPSIS

In shell:

   $ zcat access.log.gz | grep -v 127.0.0.1 | grep -c POST

In perl5:

  use Process::Pipeline;

  my $pipeline = Process::Pipeline->new
    ->push(sub { my $p = shift; $p->cmd("zcat", "access.log.gz")   })
    ->push(sub { my $p = shift; $p->cmd("grep", "-v", "127.0.0.1") })
    ->push(sub { my $p = shift; $p->cmd("grep", "-c", "POST"       });

  my $result = $pipeline->start;
  if ($result->is_success) {
     my $fh = $result->fh; # output filehandle of $pipeline
     say <$fh>;
  }

In perl5 with DSL:

  use Process::Pipeline::DSL;

  my $pipeline = proc { "zcat", "access.log.gz"   }
                 proc { "grep", "-v", "127.0.0.1" }
                 proc { "grep", "-c", "POST"      };

  my $result = $pipeline->start;
  if ($result->is_success) {
     my $fh = $result->fh; # output filehandle of $pipeline
     say <$fh>;
  }

=head1 DESCRIPTION

Process::Pipeline helps you write a pipeline of processes.

=head1 MOTIVATION

It is known that we should avoid shell-invocation in perl.
But, because the notation of shell is very convenient,
I sometimes find myself invoking shell. Oops.

The main reason for invoking shell in perl is
that perl does not have as convenient notation as shell has.

Process::Pipeline try to give an easy pipeline notation to perl. Why don't you change

    chomp(my $num = `zcat access.log.gz | grep -v 127.0.0.1 | grep -c POST`);

into

    use Process::Pipeline::DSL;
    my $p = proc { "zcat", "access.log.gz"   }
            proc { "grep", "-v", "127.0.0.1" }
            proc { "grep", "-c", "POST"      };
    my $r = $p->start;
    if ($r->is_success) {
      my $fh = $r->fh;
      chomp(my $num = <$fh>);
    }

=head1 METHODS

=head2 new

  my $pipeline = Process::Pipeline->new;

Constructor.

=head2 push

  $pipeline->push(sub {
    my $p = shift;
    $p->cmd("zcat", "access.log.gz");
  });
  $pipeline->push(sub {
    my $p = shift;
    $p->set("2>", "/dev/null");
    $p->cmd("zcat", "access.log.gz");
  });

Push a Process::Pipeline::Process object to the pipeline.

=head2 start

   my $result = $pipeline->start;

Start the pipeline. It returns a Process::Pipeline::Result object.

   my $result = $pipeline->start;
   my $bool   = $reuslt->is_success; # all commands exit successfully
   my $fh     = $reuslt->fh;         # pipeline's output filehandle

=head1 DSL

There is a DSL for Process::Pipeline. Process::Pipeline::DSL exports
C<proc> and C<set> functions, and you can construct pipelines easily.

  use Process::Pipeline::DSL;
  my $p = proc { "git", "archive", "--format=tar", "--prefix=repo/", "HEAD" }
          proc { set ">" => "repo.tar.gz"; "gzip" };
  my $r = $p->start;

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
