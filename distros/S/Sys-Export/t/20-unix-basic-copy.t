use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::Unix;
use File::stat;
use Socket;
use Fcntl qw( S_IFDIR S_IFREG S_IFLNK S_ISLNK S_IFCHR S_IFSOCK );
use autodie;

my $tmp= File::Temp->newdir;

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir, log => 'trace');
note "exporter src: '".$exporter->src."' dst: '".$exporter->dst."'";

umask 022;
mkdir "$tmp/usr";
mkdir "$tmp/usr/local";
chmod 0700, "$tmp/usr";
mkfile "$tmp/usr/local/datafile", "Just some data\n", 0644;

my @mode_check= (
  [ 'usr',                 (S_IFDIR|0700) ],
  [ 'usr/local',           (S_IFDIR|0755) ],
  [ 'usr/local/datafile',  (S_IFREG|0644) ],
);

subtest symlinks => sub {
   # Only test symlink creation on platforms that support it
   unless (eval { symlink "./datafile", "$tmp/usr/local/datafile2" or die }) {
      note "symlink check: ".($@//$!);
      skip_all "No symlink support on $^O";
   }
   symlink "/usr/local/datafile", "$tmp/usr/local/datafile-abs" or die;
   symlink "/nonexistent", "$tmp/usr/link-to-nonexistent" or die;
   symlink "/usr", "$tmp/usr/up-abs" or die;

   push @mode_check, [ 'usr/local/datafile2', (S_IFLNK|0777) ];
   ok( $exporter->add('usr/local/datafile2'), 'add datafile2' );
   ok( defined $exporter->dst_path_set->{"usr/local/datafile"}, 'symlink target also exported' );

   push @mode_check, [ 'usr/local/datafile-abs', (S_IFLNK|0777) ];
   ok( $exporter->add('usr/local/datafile-abs'), 'add datafile-abs' );
   ok( defined $exporter->dst_path_set->{"usr/local/datafile"}, 'symlink target also exported' );

   push @mode_check, [ 'usr/link-to-nonexistent', (S_IFLNK|0777) ];
   ok( $exporter->add('usr/link-to-nonexistent'), 'add dangling symlink' );

   push @mode_check, [ 'usr/up-abs', (S_IFLNK|0777) ];
   ok( $exporter->add('usr/up-abs/up-abs/up-abs'), 'add self-following symlink to /usr' );
};

# If the symlink target wasn't exported above, export it now
if (!defined $exporter->dst_path_set->{"usr/local/datafile"}) {
   ok( $exporter->add('usr/local/datafile'), 'add datafile' );
}

subtest hardlinks => sub {
   # Only test hardlink creation on platforms that support it
   unless (eval { link "$tmp/usr/local/datafile", "$tmp/usr/local/hardlink" or die }) {
      note "hardlink check: ".($@//$!);
      skip_all "No hardlink support on $^O";
   }

   push @mode_check, [ 'usr/local/hardlink', (S_IFREG|0644) ];
   ok( $exporter->add('/usr/local/hardlink'), 'link hardlink to datafile' );
   is( stat($exporter->dst_abs . 'usr/local/datafile')->ino,
       stat($exporter->dst_abs . 'usr/local/hardlink')->ino,
       'hardlink has same inode' );
};

subtest devnodes => sub {
   # Only test device node creation when running as root and on filesystems which permit them
   unless (eval { Sys::Export::Unix::_mknod_or_die("$tmp/devnull", S_IFCHR|0777, 1, 3) }) {
      note "mknod check: $@";
      skip_all "Can't create device nodes in current environment";
   }

   chmod(0777, "$tmp/devnull") or die; # mknod is affected by umask
   push @mode_check, [ 'devnull', (S_IFCHR|0777) ];
   ok( $exporter->add('devnull'), 'create char device devnull' );
   my $dev_stat= stat($exporter->dst_abs . 'devnull');
   is( [ Sys::Export::Unix::_dev_major_minor($dev_stat->rdev) ], [ 1, 3 ], 'correct major/minor' );
};

# Only test socket creation on platforms that support it
subtest sockets => sub {
   my $s;
   skip_all "No unix-socket support on $^O"
      unless eval {
         socket($s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0) or die;
         bind($s, Socket::pack_sockaddr_un("$tmp/socket.sock")) or die;
         S_IFSOCK or die; # Oddly, Win11 can get past two lines above, but lacks S_IFSOCK?
      };

   push @mode_check, [ 'socket.sock', (S_IFSOCK|0755) ];
   ok( $exporter->add('socket.sock'), 'add socket' );
};

subtest mode_checks => sub {
   skip_all "Win32 doesn't respect unix permissions anyway"
      if $^O eq 'MSWin32';
   for (@mode_check) {
      ok( my $stat= lstat($exporter->dst_abs . $_->[0]), "$_->[0] exists" );
      my $mode= $stat->mode;
      # On FreeBSD, symlinks are affected by umask.  On Linux, they are always 0777.
      # In both cases, the kernel ignores the permissions on the symlink itself,
      # so quickest workaround is to just set them all.
      $mode |= 0777 if S_ISLNK($mode);
      is( $mode, $_->[1], "$_->[0] mode" );
   }
};

done_testing;
