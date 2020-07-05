package Mojo::IOLoop::ReadWriteProcess::Namespace;
use Mojo::Base -base;
use Mojo::File 'path';
use Carp 'confess';
use Config;

use constant {
  CLONE_ALL       => 0,
  CLONE_NEWNS     => 0x00020000,
  CLONE_NEWIPC    => 0x08000000,
  CLONE_NEWNET    => 0x40000000,
  CLONE_NEWUTS    => 0x04000000,
  CLONE_NEWPID    => 0x20000000,
  CLONE_NEWUSER   => 0x10000000,
  CLONE_NEWCGROUP => 0x02000000,
  MS_REC          => 0x4000,
  MS_PRIVATE      => 1 << 18,
  MS_NOSUID       => 2,
  MS_NOEXEC       => 8,
  MS_NODEV        => 4,
};

our @EXPORT_OK = (
  qw(CLONE_ALL CLONE_NEWNS CLONE_NEWIPC CLONE_NEWUTS),
  qw(CLONE_NEWNET CLONE_NEWPID CLONE_NEWUSER CLONE_NEWCGROUP),
  qw(MS_REC MS_PRIVATE MS_NOSUID MS_NOEXEC MS_NODEV)
);
use Exporter 'import';

sub _get_unshare_syscall {

  confess "Only Linux is supported" unless $^O eq 'linux';

  my $machine = (POSIX::uname())[4];
  die "Could not get machine type" unless $machine;

  # if we're running on an x86_64 kernel, but a 32-bit process,
  # we need to use the i386 syscall numbers.
  $machine = "i386" if ($machine eq "x86_64" && $Config{ptrsize} == 4);

  my $prctl_call
    = $machine
    =~ /^i[3456]86|^blackfin|cris|frv|h8300|m32r|m68k|microblaze|mn10300|sh|parisc$/
    ? 310
    : $machine eq "s390" ? 303

    : $machine eq "x86_64" ? 272
    : $machine eq "ppc"    ? 282
    : $machine eq "ia64"   ? 1296
    :                        undef;

  unless (defined $prctl_call) {
    delete @INC{
      qw<syscall.ph asm/unistd.ph bits/syscall.ph _h2ph_pre.ph
        sys/syscall.ph>
    };
    my $rv = eval { require 'syscall.ph'; 1 }     ## no critic
      or eval { require 'sys/syscall.ph'; 1 };    ## no critic

    $prctl_call = eval { &SYS_unshare; };
  }
  return $prctl_call;
}

sub _get_mount_syscall {

  confess "Only Linux is supported" unless $^O eq 'linux';

  my $machine = (POSIX::uname())[4];
  die "Could not get machine type" unless $machine;

  # if we're running on an x86_64 kernel, but a 32-bit process,
  # we need to use the i386 syscall numbers.
  $machine = "i386" if ($machine eq "x86_64" && $Config{ptrsize} == 4);

  my $prctl_call;

#  $machine
# =~ /^i[3456]86|^blackfin|cris|frv|h8300|m32r|m68k|microblaze|mn10300|sh|parisc$/
# ? 310
# : $machine eq "s390"  ? 303
#
# : $machine eq "x86_64"  ? 272
# : $machine eq "ppc"     ? 282
# : $machine eq "ia64"    ? 1296
# :


  unless (defined $prctl_call) {
    delete @INC{
      qw<syscall.ph asm/unistd.ph bits/syscall.ph _h2ph_pre.ph
        sys/syscall.ph>
    };
    my $rv = eval { require 'syscall.ph'; 1 }     ## no critic
      or eval { require 'sys/syscall.ph'; 1 };    ## no critic

    $prctl_call = eval { &SYS_mount; };
  }
  return $prctl_call;
}

sub mount {
  my ($self, $arg1, $arg2, $arg3, $opts) = (@_);
  $arg3 //= 0;
  local $!;
  my $ret
    = syscall(_get_mount_syscall(), my $s = $arg1, my $t = $arg2, $arg3, $opts,
    0);

  warn "mount is unavailable on this platform." if $!{EINVAL};
  warn "Mount failed! $!"                       if $!;
  return $ret;
}

sub unshare {
  my ($self, $opts) = @_;
  local $!;
  my $ret = syscall(_get_unshare_syscall(), $opts, 0, 0);

  warn "unshare is unavailable on this platform." if $!{EINVAL};
  warn "Unshare failed! $!"                       if $!;
  return $ret;
}

sub isolate {
  my ($self, $procdir) = shift;
  $procdir //= "/proc";
  $self->mount("none", "/", 0, MS_REC | MS_PRIVATE);
  warn "Failed isolating proc"
    if $self->mount("none", $procdir, 0,      MS_REC | MS_PRIVATE) != 0
    || $self->mount("proc", $procdir, "proc", MS_NOSUID | MS_NOEXEC | MS_NODEV)
    != 0;
}

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Namespace - Namespace object for Mojo::IOLoop::ReadWriteProcess.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::Namespace qw(CLONE_ALL);

    my $ns = Mojo::IOLoop::ReadWriteProcess::Namespace->new();

    $ns->unshare(CLONE_ALL);
    $ns->mount("proc", "/proc", "proc");
    $ns->isolate();

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Namespace> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 unshare

    use Mojo::IOLoop::ReadWriteProcess::Namespace qw(CLONE_ALL);
    my $ns = Mojo::IOLoop::ReadWriteProcess::Namespace->new();
    $ns->unshare(CLONE_ALL);

Wrapper around the unshare syscall, accepts the same arguments,
constants can be exported from L<Mojo::IOLoop::ReadWriteProcess::Namespace>.

=head2 mount

    my $ns = Mojo::IOLoop::ReadWriteProcess::Namespace->new();
    $ns->mount("proc", "/proc", "proc");

Wrapper around the mount syscall, accepts the same arguments.

=head2 isolate

    my $ns = Mojo::IOLoop::ReadWriteProcess::Namespace->new();
    $ns->isolate();

Mount appropriately /proc to achieve process isolation during process containment, see L<Mojo::IOLoop::ReadWriteProcess::Container>.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut


1;
