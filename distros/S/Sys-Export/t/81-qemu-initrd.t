use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Cwd 'abs_path';

=head1 DESCRIPTION

This test creates an initrd from an Alpine docker image, and then runs it inside qemu,
verifying the kernel output includes the mesage from the init script.
You need docker and qemu-system-x86_64 installed, and access to a linux kernel for this to work.
(ubuntu distros typically mount them at /boot with a 'vmlinuz' symlink, but you also might need
to make it user-readable)

Example Usage:

  DOCKER_TESTS=1 DOCKER_TEST_IMAGE_NAME=test-sys-export \
    KERNEL_BZIMAGE=/boot/vmlinuz prove -lv t/81-qemu-initrd.t

=cut

#$File::Temp::KEEP_ALL=1;

# Docker access is equivalent to root access, so not enabled by default
skip_all 'Set env DOCKER_TESTS=1 to run this test'
   unless $ENV{DOCKER_TESTS};

skip_all 'This test requires KERNEL_BZIMAGE=/path/to/bzImage'
   unless length $ENV{KERNEL_BZIMAGE} && -f $ENV{KERNEL_BZIMAGE};

skip_all "Can't find qemu-system-x86_64"
   unless `which qemu-system-x86_64` && $? == 0;

skip_all 'No docker access, or unable to fetch alpine image'
   unless system('docker','pull','alpine') == 0;

# If the user provided a docker image name, we can cache things into the image.
# Otherwise we need to pass all of that into the 'run' command and perform the
# package installs as part of the entrypoint.
my $tmp= File::Temp->newdir(CLEANUP => !$ENV{DEBUG_INITRD});
diag "Leaving temp files at $tmp" if $ENV{DEBUG_INITRD};
my @cmd;
if ($ENV{DOCKER_TEST_IMAGE_NAME}) {
   mkfile("$tmp/Dockerfile", <<~'END');
      FROM alpine
      RUN apk add perl patchelf
      END
   system(qw( docker build -t ), $ENV{DOCKER_TEST_IMAGE_NAME}, $tmp) == 0
      or die "Can't build docker image $ENV{DOCKER_TEST_IMAGE_NAME}";
   @cmd= ( $ENV{DOCKER_TEST_IMAGE_NAME}, 'perl', "/opt/export/export.pl" );
} else {
   warn "You can cache the Alpine package downloads by specifying DOCKER_TEST_IMAGE_NAME";
   mkfile("$tmp/entrypoint.sh", <<~END, 0755);
      apk add perl patchelf
      perl /opt/export/export.pl
      END
   @cmd= ( 'alpine', 'sh', '/opt/export/entrypoint.sh' );
}

# This is the script that runs inside docker to perform the export into the initrd
my ($uid, $gid)= ($<, $(+0);
mkfile("$tmp/export.pl", <<~END_PL, 0755);
   #! /usr/bin/perl
   use v5.26;
   use warnings;
   use lib "/opt/sys-export/lib";
   use Sys::Export::CPIO;
   use Sys::Export -src => '/', -dst => Sys::Export::CPIO->new("/opt/export/initrd.cpio");
   chown $uid, $gid, "/opt/export/initrd.cpio";
   add qw( proc sys dev tmp run var usr
           bin/busybox bin/sh bin/date bin/cat bin/mount
         ),
      [ file755 => 'init', { data_path => "/opt/export/init.sh" } ];
   finish;
   exit 0;
   END_PL

# This is the script that is used as 'init' within the initrd, and generates a string that we
# look for in the kernel output.
mkfile("$tmp/init.sh", <<~'END_SH', 0755);
   #! /bin/sh
   mount -t devtmpfs dev /dev
   mount -t proc proc /proc
   mount -t sysfs sys /sys
   echo "Init Script Started"
   echo $PATH
   date
   END_SH

# Launch docker with source code at /opt/sys-export and tmp dir at /opt/export/
@cmd= (qw( docker run --init --rm -w / ),
   -v => abs_path((__FILE__ =~ s,[^/]+\z,,r).'..').':/opt/sys-export',
   -v => "$tmp:/opt/export",
   @cmd);
$,= ' ';
say @cmd;
is( system(@cmd), 0, 'docker process succeeded' )
&& ok( -f "$tmp/initrd.cpio" && -s "$tmp/initrd.cpio" > 0, 'initrd.cpio created' )
or die "Can't continue without initrd";

my $cmdline= "console=ttyS0 earlyprintk=serial,ttyS0,115200n8 panic=1 oops=panic loglevel=8";
my @args= (-m => 1024, -kernel => $ENV{KERNEL_BZIMAGE},
      -initrd => "$tmp/initrd.cpio", -append => "'$cmdline'", '-nographic',
      -serial => 'mon:stdio', '-no-reboot');
note "qemu-system-x86_64 @args";
my $output= `qemu-system-x86_64 @args`;
is( $?, 0, 'qemu-system-x86_64' );
note $output =~ s/[\0-\x09\x0E-\x1F]+//gr;
like( $output, qr/Init Script Started/, 'found start message' );

done_testing;
