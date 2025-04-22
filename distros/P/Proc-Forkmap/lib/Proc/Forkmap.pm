package Proc::Forkmap;
use IO::Select;
use POSIX ":sys_wait_h";
use File::Temp qw(tempfile);
use strict;
use warnings;
use v5.10;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw/
  forkmap_settings
  forkmap
/;

our $VERSION = '0.2305';

my $MAX_PROCS = 4;
my $TIMEOUT = 0;
my $IPC = 1;
my $TEMPFILE_DIR;

sub forkmap_settings {
  my %opts = @_;
  $MAX_PROCS = $opts{MAX_PROCS} if exists $opts{MAX_PROCS};
  $TIMEOUT = $opts{TIMEOUT} if exists $opts{TIMEOUT};
  $IPC = $opts{IPC} if exists $opts{IPC};
  $TEMPFILE_DIR = $opts{TEMPFILE_DIR} if exists $opts{TEMPFILE_DIR};
}

sub forkmap (&@) {
  my $fn = shift;
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my @args = @_;

  unless ($IPC) {
    my $procs = 0;
    my $i = 0;

    while ($i <= $#args || $procs > 0) {
      while ($procs < $MAX_PROCS && $i <= $#args) {
        my $idx = $i;
        my $pid = fork();
        die "bad fork: $!" unless defined $pid;
        if ($pid == 0) {
          if ($TIMEOUT) {
            local $SIG{ALRM} = sub { die "timeout: pid [$$]" };
            alarm $TIMEOUT;
            eval {
              local $_ = $args[$idx];
              $fn->($_);
              alarm 0;
            };
            if ($@) {
              die "$@";
            }
          } else {
            local $_ = $args[$idx];
            $fn->($_);
          }
          $cb->($idx) if $cb;
          exit 0;
        }
        $procs++;
        $i++;
      }

      while (waitpid(-1, WNOHANG) > 0) {
        $procs--;
      }
      select undef, undef, undef, 0.1 if $procs >= $MAX_PROCS || $i > $#args;
    }
    return;
  }

  my $sel = IO::Select->new();
  my @res;
  my $procs = 0;
  my $i = 0;

  while ($i <= $#args || $procs > 0) {
    while ($procs < $MAX_PROCS && $i <= $#args) {
      pipe(my $r, my $w) or die "bad pipe: $!";
      my $idx = $i;
      my $pid = fork();
      die "bad fork: $!" unless defined $pid;
      if ($pid == 0) {
        close $r;
        my ($fh, $fname) = tempfile(DIR => $TEMPFILE_DIR, UNLINK => 0);
        if ($TIMEOUT) {
          local $SIG{ALRM} = sub { die "timeout: pid [$$] index [$idx]" };
          alarm $TIMEOUT;
          eval {
            local $_ = $args[$idx];
            my $t = $fn->($_);
            print $fh $t if defined $t;
            alarm 0;
          };
          if ($@) {
            close $fh if defined fileno $fh;
            unlink $fname if defined $fname;
            die "$@";
          }
        } else {
          eval {
            local $_ = $args[$idx];
            my $t = $fn->($_);
            print $fh $t if defined $t;
          };
          if ($@) {
            close $fh if defined fileno $fh;
            unlink $fname if defined $fname;
            die "$@";
          }
        }
        close $fh;
        print $w "$idx:$fname\n";
        close $w;
        exit 0;
      }
      close $w;
      $sel->add($r);
      $procs++;
      $i++;
    }

    for my $fh ($sel->can_read(0.1)) {
      my $line = <$fh>;
      if (defined $line) {
        chomp $line;
        my ($idx, $fname) = split /:/, $line, 2;
        open my $f, "<", $fname or do {
          warn "bad file [$fname]: $!";
          $res[$idx] = undef;
          next;
        };
        my $d = do {local $/; <$f>};
        close $f;
        unlink $fname;

        if ($cb) {
          $cb->($idx, $d);
        } else {
          $res[$idx] = $d;
        }
      } else {
        $sel->remove($fh);
        close $fh;
      }
    }
    while (waitpid(-1, WNOHANG) > 0) {
      $procs--;
    }
  }

  return $cb ? undef : @res;
}

1;

__END__

=head1 NAME

Proc::Forkmap - map with forking

=head1 SYNOPSIS

  use Proc::Forkmap;

  # basic usage
  my @results = forkmap { process_item($_) } @items;

  # with callback
  forkmap { process_item($_) } @items, sub {
    my ($idx, $result) = @_;
    print "$result\n" if defined $result;
  };

  # with timeout
  forkmap_settings(TIMEOUT => 50);  # 50 second timeout
  my @results = forkmap { long_running_task($_) } @items;

  # with no IPC
  forkmap_settings(IPC => 0);  # no tempfiles created
  forkmap { job($_) } @items;

=head1 DESCRIPTION

This module provides C<forkmap>, with syntax similar to Perl's built-in C<map> function.
The function evaluates code blocks concurrently, with an optional callback.

=head2 forkmap

  forkmap BLOCK LIST [, CODE reference]

=head2 forkmap_settings

  # change your FM settings

  forkmap_settings(
    TIMEOUT => $seconds,  # forked proc timeout in seconds (default: 0 = no timeout)
    MAX_PROCS => $n,  # maximum concurrent forked procs (default: 4)
    IPC => $ipc,  # enable return data via tempfiles (default: 1)
    TEMPFILE_DIR => $dir  # directory to store tempfiles (default: File::Temp default)
  );

Modify runtime parameters for C<forkmap>.

=over 4

=item * MAX_PROCS

Maximum number of concurrent forked processes (default: 4).

=item * TIMEOUT

Time in seconds to allow each process to run before killed (default: 0 = no timeout).

=item * IPC

Enable = 1 or disable = 0 return data (default: 1).

If enabled, the return value of the BLOCK must be a scalar.
The value is then sent via temporary files.
If you need to return complex structures (arrays, hashes, objects), serialize them yourself
inside the code block (for example using JSON or Storable).

=item * TEMPFILE_DIR

Directory to store tempfiles (default: File::Temp default).

=back

=head1 CALLBACK MODE

If the last argument to C<forkmap> is a CODE reference, C<forkmap> invokes the callback.
If the forked process completes, the callback is invoked either when the process
completes (when IPC = 1) or before the process exits (when IPC = 0), for each process.
The callback is called with C<($index, $output)>, where C<$index> is the
index of the item in the array mapped by the function, and C<$output> is the result returned
by the code block for that item, if any. The result will be undefined unless IPC is enabled.

=head1 AUTHOR

Andrew Shapiro, C<< <trski@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-forkmap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-Forkmap>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Andrew Shapiro.

This library is free software and may be distributed under the same terms as perl itself.
See https://dev.perl.org/licenses/.
