#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Spec ();
use File::Temp ();
use Test::More tests => 28;
use Test::Exception;

my $test_package = 'test-package-1-1.src.rpm';
my $sha1sum = 'e99e636995779f68198524c39c5ee7d6e0c8fc2a';

use PkgForge::Source::SRPM;

my $source = PkgForge::Source::SRPM->new( basedir => 't',
                                          file    => $test_package );

isa_ok( $source, 'PkgForge::Source::SRPM' );

can_ok( $source, ('fullpath') );

can_ok( $source, ('gen_sha1sum') );

can_ok( $source, ('check_sha1sum') );

can_ok( $source, ('can_handle') );

can_ok( $source, ('validate') );

can_ok( $source, qw(type basedir file sha1sum) );

is( $source->type, 'SRPM', 'type is correct' );

is( $source->file, $test_package, 'package is correct' );

my $pwd = Cwd::abs_path();
my $t = File::Spec->catdir( $pwd, 't' );

is( $source->basedir, $t, 'basedir is correct' );

my $fullpath = File::Spec->catfile( $t, $test_package );

is( $source->fullpath, $fullpath, 'fullpath is correct' );

is( $source->gen_sha1sum, $sha1sum, 'sha1sum generator is correct' );

is( $source->sha1sum, $sha1sum, 'sha1sum accessor is correct' );

is( $source->check_sha1sum, 1, 'sha1sum check' );

my $testfile = File::Temp->new( SUFFIX => '.src.rpm' );
my $test_pkg = $testfile->filename;

lives_ok { $source->can_handle('foo.txt') };
lives_ok { $source->can_handle('foo.src.rpm') };
lives_ok { $source->can_handle($test_pkg) };

SKIP: {
  eval { require RPM2 };

  skip 'RPM2 not installed', 7 if $@;

  throws_ok { $source->validate('foo.txt') } qr/^The SRPM file name must end with \.src\.rpm/, 'Validates file name';

  throws_ok { $source->validate('foo.src.rpm') } qr/^The SRPM file 'foo.src.rpm' does not exist/, 'Validates file existence';

  throws_ok { $source->validate($test_pkg) } qr/^The file '\Q$test_pkg\E' is not an SRPM/;

  is( $source->validate, 1, 'can validate' );
  is( $source->validate($source->fullpath), 1, 'can validate with argument' );

  is( PkgForge::Source::SRPM->can_handle($source->fullpath), 1, 'can handle SRPM' );
  is( PkgForge::Source::SRPM->can_handle($test_pkg), 0, 'cannot handle non-SRPM' );

}
   
dies_ok { PkgForge::Source::SRPM->can_handle() } 'can_handle dies when no file';


my $source2 = PkgForge::Source::SRPM->new( $test_package );

isa_ok( $source, 'PkgForge::Source::SRPM' );

is( $source->basedir, $t, 'base directory is correct' );

is( $source->file, $test_package, 'file name is correct' );
