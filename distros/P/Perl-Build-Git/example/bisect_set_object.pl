#!/usr/bin/env perl

#   git bisect start
#
#
#
#
use strict;
use warnings;
use utf8;
use Cwd qw( cwd );

# This is a bisect runner I used to find the first commit Set::Object mysteriously started passing tests at
#
# I did:
#
#   cd perl/
#   git bisect HEAD v5.16.2
#   git bisect run ./bisect_set_object.pl
#
# And 2 hours later, it told me that the first commit that the mysterious passing of tests
# began at, was 1a904fc88069e249a4bd0ef196a3f1a7f549e0fe
#
# When it was done, here is the contents of my /tmp/xbuild
#
#total 84
#drwxr-xr-x 17 kent kent  4096 Apr  6 16:09 .
#drwxrwxrwt 73 root root 20480 Apr  6 16:22 ..
#drwxr-xr-x  4 kent kent  4096 Apr  6 14:26 v5.16.0-139-gc6b15a5
#drwxr-xr-x  4 kent kent  4096 Apr  6 14:13 v5.16.0-2-g559550a
#drwxr-xr-x  4 kent kent  4096 Apr  6 13:44 v5.17.10-44-g97927b0
#drwxr-xr-x  4 kent kent  4096 Apr  6 14:46 v5.17.4-10-ga310a8f
#drwxr-xr-x  4 kent kent  4096 Apr  6 14:59 v5.17.5-229-g140b12a
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:06 v5.17.5-503-g2339cd9
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:22 v5.17.6-113-gdb9306a
#drwxr-xr-x  4 kent kent  4096 Apr  6 14:52 v5.17.6-183-g2308343
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:13 v5.17.6-46-g4ded55f
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:31 v5.17.6-79-g05a206c
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:44 v5.17.6-87-g07d01d6
#drwxr-xr-x  4 kent kent  4096 Apr  6 16:09 v5.17.6-88-g1a904fc
#drwxr-xr-x  4 kent kent  4096 Apr  6 16:01 v5.17.6-89-g5b50f57
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:54 v5.17.6-91-gaaee23a
#drwxr-xr-x  4 kent kent  4096 Apr  6 15:38 v5.17.6-96-ge1b1450
#
# I can also do a successive repeat of this same bisect procedure now without incurring the need to build all the above perls.
#

use Perl::Build::Git;

my $man         = [qw( man1dir man3dir siteman1dir siteman3dir  )];
my $no_man_opts = [ map { '-D' . $_ . '=none' } @{$man} ];
my $result      = Perl::Build::Git->install_git(
  preclean          => 1,
  persistent        => 1,
  git_root          => '/home/kent/perl/perl',
  cache_root        => '/tmp/xbuild',
  configure_options => [
    '-de',               # quiet automatic
    '-Dusedevel',        # "yes, ok, its a development version"
    @{$no_man_opts},     # man pages are ugly
    '-U versiononly',    # use bin/perl, not bin/perl5.17.1
  ],
);
my $test_file = {
  store_at => '/tmp/Set-Object-1.29.tar.gz',
  src_uri  => 'http://cpan.metacpan.org/authors/id/S/SA/SAMV/Set-Object-1.29.tar.gz',
};
if ( not -e $test_file->{store_at} ) {
  system( 'wget', '-O', $test_file->{store_at}, $test_file->{src_uri} );
}

my $expect_fail = 1;

my $cwd = cwd();

$result->run_env(
  sub {
    my $cpanm = $result->bin_path . '/cpanm';
    if ( not -e $cpanm ) {
      system('curl -L http://cpanmin.us | perl - App::cpanminus');
    }
    my $tmpdir = File::Temp->newdir();

    safe_system_tool( 'cpanm', '-v', '--notest', '--installdeps', $test_file->{store_at} );

    chdir( $tmpdir->dirname );
    safe_system_tool( 'tar', '-xf', $test_file->{store_at}, '--strip-components=1' );
    safe_system_tool( 'perl', './Makefile.PL' );
    safe_system_tool('make');
    safe_system_target( 'prove', '-bvr', 't/object/union.t' );
  }
);

target_success();

sub tooling_error {
  *STDERR->print("\e[34m tooling error\e[0m\n");
  chdir($cwd);
  if ($expect_fail) {
    exit 1;
  }
  exit 0;
}

sub target_error {
  *STDERR->print("\e[34m target error\e[0m\n");
  chdir($cwd);
  if ($expect_fail) {
    exit 0;
  }
  exit 1;
}

sub target_success {
  *STDERR->print("\e[34m target success\e[0m\n");

  chdir($cwd);
  if ($expect_fail) {
    exit 1;
  }
  exit 0;
}

sub safe_system_tool {
  my (@args) = @_;
  *STDERR->print("\e[31m@args\e[0m\n");
  my $result = system(@args);
  if ($result) {
    *STDERR->print("\e[33m non-zero exit = $result\e[0m\n");
    tooling_error;
  }
}

sub safe_system_target {
  my (@args) = @_;
  *STDERR->print("\e[31m@args\e[0m\n");
  my $result = system(@args);
  if ($result) {
    *STDERR->print("\e[33m non-zero exit = $result\e[0m\n");
    target_error;
  }
  target_success;
}

