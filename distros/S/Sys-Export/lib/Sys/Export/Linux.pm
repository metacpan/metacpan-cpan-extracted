package Sys::Export::Linux;

# ABSTRACT: Export subsets of a Linux system, including GNU libc special cases
our $VERSION = '0.006'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::Unix';
use Cwd 'abs_path';
use Carp;
use Sys::Export 'filedata';
use Sys::Export::LogAny '$log';

sub _build__trace_deps {
   my $self= shift;
   if ($self->_can_run_in_src) {
      # Seems Solaris has an 'strace' but it isn't compatible enough to pass tests.
      $^O eq 'linux' or croak "Only Linux strace is supported";
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


sub parse_ld_so_conf($self, $conf_path= 'etc/ld.so.conf') {
   my $data= filedata($self->src_abs . $conf_path);
   my @libs;
   for (split /\n/, $$data) {
      chomp;
      next if /^\s*(#|\z)/;
      if (/^\s*include (\S+)/) {
         my $pattern= $1;
         # relative paths are relative to the config file's parent directory
         my $prefix= $pattern =~ s{^/}{}? '' : ($conf_path =~ s{[^/]+\z}{}r);
         push @libs, $self->parse_ld_so_conf($_)
            for $self->src_glob($prefix.$pattern);
      }
      elsif (m{^/}) {
         push @libs, substr($_, 1);
      }
      else {
         $log->warn("parse_ld_so_conf: unknown syntax at '$_'");
      }
   }
   return @libs;
}

sub _build_src_lib_path($self) {
   my $paths= $self->next::method();
   # ld.so.conf may or may not be used on this host
   if (defined $self->_src_abs_path('etc/ld.so.conf')) {
      eval { $paths= $self->_distinct_abs_directories(1, @$paths, $self->parse_ld_so_conf) }
         or $self->log->warn("Failed to parse ld.so.conf: $@");
   }
   return $paths;
}


sub parse_nsswitch_conf($self, $conf_path= 'etc/nsswitch.conf') {
   my $data= filedata($self->src_abs . $conf_path);
   my @db_conf;
   for (split /\n/, $$data) {
      chomp;
      next if /^\s*(#|\z)/;
      if (m{^\s*([^\s:]+)\s*:\s*(\S.+)}) {
         push @db_conf, $1 => [ split /\s+/, $2 ];
      }
      else {
         $log->warn("parse_nsswitch_conf: unknown syntax at '$_'");
      }
   }
   return @db_conf;
}


sub add_nsswitch_libs($self, @module_names) {
   if (!@module_names) {
      my %seen;
      for ($self->parse_nsswitch_conf) {
         next unless ref eq 'ARRAY';
         ++$seen{$_} for @$_;
      }
      @module_names= sort keys %seen;
   }
   my @libpath= $self->src_lib_path_list;
   ns_module: for (@module_names) {
      my $pattern= "libnss_$_.*";
      for my $libdir (@libpath) {
         $log->tracef("Look for %s in %s", $pattern, $libdir);
         if (my @match= $self->src_glob("$libdir/$pattern")) {
            $self->add(@match);
            next ns_module;
         }
      }
      $log->warn("glibc nss module not found: $_");
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
delete @{Sys::Export::Linux::}{qw( croak carp confess abs_path filedata )};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Linux - Export subsets of a Linux system, including GNU libc special cases

=head1 SYNOPSIS

  use Sys::Export::Linux;
  my $exporter= Sys::Export::Linux->new(
    src => '/', dst => '/initrd'
  );
  $exporter->add('bin/busybox');
  $exporter->add_passwd;
  $exporter->add_localtime("UTC");

=head1 DESCRIPTION

This object extends L<Sys::Export::Unix> with Linux-specific and GNU-libc-specific helpers and
special cases.  It also supports Linux without GNU libc, and possibly GNU libc without Linux.

See C<Sys::Export::Unix> for the list of core attributes and methods.

=head1 METHODS

=head2 parse_ld_so_conf

  @lib_paths= $exporter->parse_ld_so_conf($filename = 'etc/ld.so.conf');

Return a list of library paths parsed from a ld.so.conf file.

=head2 parse_nsswitch_conf

  %db_info= $exporter->parse_nsswitch_conf($filename => 'etc/nsswitch.conf');
  # (
  #    aliases => [ @module_names ],
  #    hosts   => [ @module_names ],
  #    ...
  # )

The GNU Libc "nsswitch" system lets you dynamically configure libraries to support various libc
database lookups.  This method returns a name/value list (suitable for constructing a hashref)
where the key is the name of the database, like C<'hosts'> or C<'passwd'>, and the value is an
arrayref of which plugins will be queries, and in what order they will be queried.

=head2 add_nsswitch_libs

  $exporter->add_nsswitch_libs;
  $exporter->add_nsswitch_libs(@module_names);

With glibc, the binaries do not directly refer to the dynamically-configured nsswitch modules,
so the modules won't get automatically included.  If you want your chroot image to be able to
do things like DNS name lookups or passwd file lookups, you need to include any NSS module
configured for them.

This method defaults to the set of all modules returned by L</parse_nsswitch_conf>, and then
adds libraries for each of them, like C<"lib64/libnss_dns.so.2">.  Missing libraries generate a
warning (not an exception).

With newer glibc, the modules 'files' and 'dns' are built-in, to aid with chroots, though the
libnss_files.so and libnss_dns.so still exist in the lib directory.
This method doesn't attempt to add a special case for omitting them.

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

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
