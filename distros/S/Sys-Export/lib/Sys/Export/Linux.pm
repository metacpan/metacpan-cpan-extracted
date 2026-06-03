package Sys::Export::Linux;

# ABSTRACT: Export subsets of a Linux system
our $VERSION = '0.004'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::Unix';
use Cwd 'abs_path';
use Carp;

sub _build__trace_deps {
   my $self= shift;
   if ($self->_can_run_in_src) {
      # Are we going to attempt chrooting?
      if ($self->src_abs ne '/') {
         $self->{cmd_path_chroot} //= do {
            chomp(my $chroot= `which chroot`);
            -x $chroot or croak "chroot command not available or not executable";
            $self->{_log_trace}->("chroot binary at $chroot") if $self->{_log_trace};
            $chroot;
         };
      }
      $self->{cmd_path_strace} //= do {
         chomp(my $strace= `which strace`);
         -x $strace or croak "strace command not available or not executable";
         $self->{_log_trace}->("strace binary at $strace") if $self->{_log_trace};
         $strace;
      };
      return $self->can('_trace_deps_linux_strace');
   }
   $self->next::method(@_);
}

sub _trace_deps_linux_strace($self, @argv) {
   # Are we going to attempt chrooting?
   unshift @argv, $self->{cmd_path_chroot}, $self->src_abs
      unless $self->src_abs eq '/';
   # Tell strace to write to a pipe, while redirecting command output to /dev/null
   open my $devnull, '+<', '/dev/null' or croak "open(/dev/null): $!";
   pipe(my $r, my $w) // croak "pipe: $!";
   pipe(my $err_r, my $err_w) // croak "pipe: $!";
   my $pid= fork // croak "fork: $!";
   if (!$pid) {
      close $r;
      close $err_r;
      eval {
         chdir $self->src_abs or die "chdir: $!";
         POSIX::dup2(fileno $devnull, 0) or die "dup2(->0): $!";
         POSIX::dup2(fileno $devnull, 1) or die "dup2(->1): $!";
         POSIX::dup2(fileno $devnull, 2) or die "dup2(->2): $!";
         POSIX::dup2(fileno $w, 3) or die "dup2(->3): $!";
         $^F= 3;
         unshift @argv, $self->{cmd_path_strace}, -o => "/proc/self/fd/3", -e => 'trace=open,openat';
         exec @argv
            or die "exec(@argv): $!";
      };
      $err_w->print($@);
      $err_w->close;
      POSIX::_exit(2); # forcibly exit rather than bubble up the stack
   }
   else {
      close $w;
      close $err_w;
      my %deps;
      my $err= do { local $/; <$err_r> };
      if (length $err) {
         waitpid($pid, 0);
         die $err;
      }
      $self->{_log_trace}->("Reading strace output") if $self->{_log_trace};
      while (<$r>) {
         $self->{_log_trace}->($_) if $self->{_log_trace};
         $deps{$1}= 1 if /^open(?:at)?\(.*?"(.*?)",.*?= [0-9]/;
      }
      $self->{_log_trace}->("Done reading strace") if $self->{_log_trace};
      waitpid($pid,0);
      my $wstat= $?;
      $self->{_log_trace}->("Command exited with $wstat") if $self->{_log_trace};
      croak "straced command failed: wstat = $wstat"
         if $wstat;
      return \%deps;
   }
}


sub add_passwd($self, %options) {
   # If the dst_userdb hasn't been created, create it by filtering the src_userdb by which
   # group and user ids have been seen during the export.
   my $db= $self->dst_userdb // Sys::Export::Unix::UserDB->new(
      auto_import => ($self->{src_userdb} //= $self->_build_src_userdb),
   );
   $db->group($_) for keys $self->dst_gid_used->%*;
   $db->user($_) for keys $self->dst_uid_used->%*;
   $db->save(\my %contents);
   my $etc_path= $options{etc_path} // 'etc';
   $self->add([ dir755  => "$etc_path", { uid => 0, gid => 0 }]);
   $self->add([ file644 => "$etc_path/passwd", $contents{passwd}, { uid => 0, gid => 0 }]);
   $self->add([ file600 => "$etc_path/shadow", $contents{shadow}, { uid => 0, gid => 0 }]);
   $self->add([ file644 => "$etc_path/group",  $contents{group},  { uid => 0, gid => 0 }]);
   $self;
}


sub add_localtime($self, $tz_name) {
   if (exists $self->{dst_path_set}{"usr/share/zoneinfo/$tz_name"}
      || ($self->_dst->can('dst_abs') && -f $self->_dst->dst_abs . $tz_name)
   ) {
      # zoneinfo is exported, and includes this timezone, so symlink to it
      $self->add([ sym => "etc/localtime" => "../usr/share/zoneinfo/$tz_name" ]);
   }
   elsif (defined (my $src_path= $self->_src_abs_path("usr/share/zoneinfo/$tz_name"))) {
      $self->add([ file644 => 'etc/localtime', { data_path => $self->src_abs . $src_path } ]);
   }
   elsif (defined (my $path= abs_path("/usr/share/zoneinfo/$tz_name"))) {
      $self->add([ file644 => 'etc/localtime', { data_path => $path } ]);
   }
   else {
      croak "Can't find 'usr/share/zoneinfo/$tz_name' in destination, source, or host filesystem";
   }
}

# Avoiding dependency on namespace::clean
delete @{Sys::Export::Linux::}{qw( croak carp confess abs_path )};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Linux - Export subsets of a Linux system

=head1 SYNOPSIS

  use Sys::Export::Linux;
  my $exporter= Sys::Export::Linux->new(
    src => '/', dst => '/initrd'
  );
  $exporter->add('bin/busybox');
  $exporter->add_passwd;
  $exporter->add_localtime("UTC");

=head1 DESCRIPTION

This object extends L<Sys::Export::Unix> with Linux-specific helpers and special cases.

See C<Sys::Export::Unix> for the list of core attributes and methods.

=head1 METHODS

=head2 add_passwd

  $exporter->add_passwd(%options)

This method writes the Linux password files ( C<< /etc/passwd >>, C<< /etc/group >>,
C<< /etc/shadow >> ) either according to the contents of L<Sys::Export::Unix/dst_userdb>
(if you used name-based exports) or according to L<Sys::Export::Unix/src_userdb> filtered by
L<Sys::Export::Unix/dst_uid_used> if C<dst_userdb> is not defined.

In the first pattern, you've either pre-specified the C<dst_userdb> users, or built it lazily
as you exported files.  The C<dst_userdb> contains the complete contents of C<passwd>, C<group>,
and C<shadow> and this method simply generates and adds those files.

In the second pattern, you want the destination userdb to be a subset of the source userdb
according to which UIDs and GIDs were actually used.

If you actually just want to copy the entire source user database files, you could just call

  $exporter->add(qw( /etc/passwd /etc/group /etc/shadow ));

so that pattern doesn't need a special helper method.

Options:

=over

=item etc_path

Specify an alternative directory to '/etc' to write the files

=back

=head2 add_localtime

  $exporter->add_localtime($tz_name);

Generate the symlink in C</etc/localtime>, *or* export the timezone file directly to that path
if the system image lacks C</usr/share/zoneinfo>.

Linux uses a symlink at C</etc/localtime> to point to a compiled zoneinfo file describing the
current time zone.  You can simply export this symlink, but if you are building a minimal
system image (like initrd) you might not be exporting the timezone database at
C</usr/share/zoneinfo>.  In that case, you want the single timezone file copied to
C</etc/localtime>.

This method looks for the zone file in your destination filesystem, and if not found there, it
looks in the source filesystem, and if not there either, it checks the host filesystem.  If it
can't find this timezone in any of those locations, it dies.

=head1 VERSION

version 0.004

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
