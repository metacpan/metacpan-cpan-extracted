package Muck::FS;

=head1 NAME

Muck::FS - A FUSE filesystem using MySQL for metadata and S3 for data store

=head1 SYNOPSIS

  use Muck::FS;
  my $fuse_self = Muck::FS->mount( \%params );

=head1 DESCRIPTION

TBD

=cut

use strict;
use warnings;
#use threads;
#use threads::shared;
use Fuse qw(fuse_get_context);
use DBI;
use Cache::Memcached;
use Carp;
use Muck::FS::VFS;
use Muck::FS::S3::AWSAuthConnection;

# block size for this filesystem
use constant BLOCK => 4096;


=head1 METHODS

=head2 mount

Mount muckFS and connect to MySQL, memcached and S3

More usage and examples to be written.

=cut

my $dbh;
my $sth;
sub fuse_module_loaded;
# evil, evil way to solve this. It makes this module non-reentrant. But, since
# fuse calls another copy of this script for each mount anyway, this shouldn't
# be a problem.
our $fuse_self;


sub mount {
   my $class = shift;
   my $self = {};
   bless($self, $class);
   my $arg = shift;

   unless ($self->fuse_module_loaded) {
      print STDERR "no fuse module loaded. Trying sudo modprobe fuse!\n";
      system "sudo modprobe fuse" || die "can't modprobe fuse using sudo!\n";
   }

   carp "mount needs 'dsn' to connect to (e.g. dsn => 'DBI:Pg:dbname=test')" 
      unless ($arg->{'dsn'});
   carp "mount needs 'mount' as mountpoint" unless ($arg->{'mount'});


   # save (some) arguments in self
   foreach ( qw( mount cachedir s3_bucket debug ) ) {
      $self->{$_} = $arg->{$_};
   }

   foreach (qw( aws_access_key_id aws_secret_access_key 
                dsn user password )) {
      carp "mount needs '$_'" unless ($arg->{$_});
   }

   # TODO we choose to add forking in the future, do it here

   ## DB Setup
   $dbh = DBI->connect( $arg->{'dsn'},
                        $arg->{'user'},
                        $arg->{'password'}, 
                        {AutoCommit => 0, RaiseError => 1} ) 
            || die $DBI::errstr;

   # Lets cache our prepared SQL statements in self
   foreach my $s ( @Muck::FS::VFS::statements ) {
      $sth->{$s->{name}} = $dbh->prepare($s->{sql}) || die $dbh->errstr();
   }


   $self->{'dbh'} = $dbh;
   $self->{'sth'} = $sth;

   ## memcached Setup
   if ( $arg->{memcached} ) {
      my $cache = new Cache::Memcached {
         'servers'      => [ "127.0.0.1:11211" ],
         'debug'        => 0,
         'compress_threshold' => 10000,
      };
      $self->{memcached} = $cache;
   }

   ## S3 Setup
   $self->{S3conn} = Muck::FS::S3::AWSAuthConnection->new(
                        $arg->{aws_access_key_id}, 
                        $arg->{aws_secret_access_key});

   ## File Handle Cache Setup
   $self->{Rfh_cache} = {};
   $self->{Wfh_cache} = {};

   $fuse_self = $self;

   Fuse::main(
      mountpoint  => $arg->{'mount'},
      mountopts   => 'allow_other',
      threaded    => '0',
      chown       => \&Muck::FS::VFS::x_chown,
      chmod       => \&Muck::FS::VFS::x_chmod,
      getattr     => \&Muck::FS::VFS::x_getattr,
      getdir      => \&Muck::FS::VFS::x_getdir,
      link        => \&Muck::FS::VFS::x_link,
      mknod       => \&Muck::FS::VFS::x_mknod,
      mkdir       => \&Muck::FS::VFS::x_mkdir,
      open        => \&Muck::FS::VFS::x_open,
      read        => \&Muck::FS::VFS::x_read,
      readlink    => \&Muck::FS::VFS::x_readlink,
      release     => \&Muck::FS::VFS::x_release,
      rename      => \&Muck::FS::VFS::x_rename,
      rmdir       => \&Muck::FS::VFS::x_unlink,
      statfs      => \&Muck::FS::VFS::x_statfs,
      symlink     => \&Muck::FS::VFS::x_symlink,
      truncate    => \&Muck::FS::VFS::x_truncate,
      utime       => \&Muck::FS::VFS::x_utime,
      unlink      => \&Muck::FS::VFS::x_unlink,
      write       => \&Muck::FS::VFS::x_write,
      debug       => ( $arg->{debug} > 2 ? 1 : 0 ),
   );
   
   exit(0) if ($arg->{'fork'});

   return 1;
}

=head2 is_mounted

Check if fuse filesystem is mounted

  if ($mnt->is_mounted) { ... }

=cut

sub is_mounted {
   my $self = shift;

   my $mounted = 0;
   my $mount = $self->{'mount'} || confess "can't find mount point!";
   if (open(MTAB, "/etc/mtab")) {
      while(<MTAB>) {
         $mounted = 1 if (/ $mount fuse /i);
      }
      close(MTAB);
   } else {
      warn "can't open /etc/mtab: $!";
   }

   return $mounted;
}


=head2 umount

Unmount your database as filesystem.

  $mnt->umount;

This will also kill background process which is translating
database to filesystem.

=cut

sub umount {
   my $self = shift;

   if ($self->{'mount'} && $self->is_mounted) {
      system "( fusermount -u ".$self->{'mount'}." 2>&1 ) >/dev/null";
      if ($self->is_mounted) {
         system "sudo umount ".$self->{'mount'} ||
         return 0;
      }
      return 1;
   }

   return 0;
}

$SIG{'INT'} = sub {
   if ($fuse_self && $$fuse_self->umount) {
      print STDERR "umount called by SIG INT\n";
   }
};

$SIG{'QUIT'} = sub {
   if ($fuse_self && $$fuse_self->umount) {
      print STDERR "umount called by SIG QUIT\n";
   }
};

sub DESTROY {
   my $self = shift;
   if ($self->umount) {
      print STDERR "umount called by DESTROY\n";
   }
}

=head2 fuse_module_loaded

Checks if C<fuse> module is loaded in kernel.

  die "no fuse module loaded in kernel"
   unless (Fuse::DBI::fuse_module_loaded);

This function in called by C<mount>, but might be useful alone also.

=cut

sub fuse_module_loaded {
   my $lsmod = `/sbin/lsmod`;
   die "can't start lsmod: $!" unless ($lsmod);
   if ($lsmod =~ m/fuse/s) {
      return 1;
   } else {
      return 0;
   }
}

sub get_context {
   my $context = fuse_get_context();
   return @$context{'uid','gid','pid'};
}


1;
__END__

=head1 EXPORT

Nothing.

=head1 BUGS

Probably.

=head1 SEE ALSO

C<FUSE (Filesystem in USErspace)> website
L<http://fuse.sourceforge.net/>

This code borrows heavily from the Fuse::DBI module on CPAN.

=head1 AUTHOR

Mike Schroeder, E<lt>mike-cpan@donorware.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by DonorWare LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

