use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Cwd 'getcwd';

=head1 DESCRIPTION

This test extracts executables (specifically busybox) from an Alpine docker container using a
path_rewrite that allows the extracted binary to be executable from the directory we extracted
it to.  Specifically, it rewrites the library path of the binary so that the libs (including
ld-musl) can be found adjacent to that binary instead of looking in /lib of the host.

Example Usage:

  DOCKER_TESTS=1 DOCKER_TEST_IMAGE_NAME=test-sys-export \
    prove -lv t/80-docker-alpine-initrd.t

=cut

# Docker access is equivalent to root access, so not enabled by default
skip_all 'Set env DOCKER_TESTS=1 to run this test'
   unless $ENV{DOCKER_TESTS};

skip_all 'No docker access, or unable to fetch alpine image'
   unless system('docker','pull','alpine') == 0;

# If the user provided a docker image name, we can cache things into the image.
# Otherwise we need to pass all of that into the 'run' command and perform the
# package installs as part of the entrypoint.
my $tmp= File::Temp->newdir;
my @cmd;
if ($ENV{DOCKER_TEST_IMAGE_NAME}) {
   mkfile("$tmp/Dockerfile", <<~'END');
   FROM alpine
   RUN apk add perl patchelf
   END
   system(qw( docker build -t ), $ENV{DOCKER_TEST_IMAGE_NAME}, $tmp) == 0
      or die "Can't build docker image $ENV{DOCKER_TEST_IMAGE_NAME}";
   @cmd= ( $ENV{DOCKER_TEST_IMAGE_NAME}, 'perl', "/export$tmp/export.pl" );
} else {
   mkfile("$tmp/entrypoint.sh", <<~END, 0755);
   apk add perl patchelf
   perl /export$tmp/export.pl
   END
   @cmd= ( 'alpine', "sh", "/export$tmp/entrypoint.sh" );
}

# This export is mapping the $tmp as /export/$tmp within the container.
# The paths are being rewritten from / to $tmp/initrd because we want to be able to execute
# them as "$tmp/initrd/busybox" from outside of the container.  So, the --interpreter needs
# to be "$tmp/initrd/lib/ld-musl-etc" instead of "/export/$tmp/initrd/lib/ld-musl-etc".
# Also need to specify 'tmp' because the actual mount point occurs at "/export/$tmp" and
# the constructor is only smart enough to check the device of "/export" before choosing tmp.
mkdir "$tmp/tmp";
mkdir "$tmp/initrd";
my $gid= $(+0;
mkfile("$tmp/export.pl", <<~END_PL, 0755);
   #! /usr/bin/perl
   use v5.26;
   use warnings;
   use lib "/opt/sys-export/lib";
   use Sys::Export -src => '/', -dst => "/export", -tmp => "/export$tmp/tmp";
   rewrite_path "/" => "$tmp/initrd/";
   add 'bin/busybox';
   finish;
   END {
      # This is running as root inside the container.
      # Make sure we can delete these files from outside docker.
      system("chgrp -R $gid /export$tmp/initrd");
      system("chmod -R g+w /export$tmp/initrd");
   }
   END_PL

# Launch docker with volume at identical path of $tmp
is( system(qw( docker run --init --rm -w / ),
   -v => getcwd().':/opt/sys-export',
   -v => "$tmp:/export$tmp",
   @cmd
), 0, 'docker process succeeded' );

like( `$tmp/initrd/bin/busybox --help 2>&1`, qr/BusyBox/, 'able to run busybox' );

done_testing;
