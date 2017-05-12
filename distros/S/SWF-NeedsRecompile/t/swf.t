#!/usr/bin/perl -w

use warnings;
use strict;
use File::Spec;

BEGIN
{
   use Test::More tests => 40;
   use_ok('SWF::NeedsRecompile', 'check_files');
}

#$SWF::NeedsRecompile::verbose = 1;

my $exampledir = File::Spec->catdir('t', 'examples');
sub egfile { File::Spec->catfile($exampledir, @_); }

my @tempfiles;
END { unlink $_ for (@tempfiles); }

# HACK: remove the OS dependency so we can test just the file
# functionality without the user's classpath (if any) getting in the
# way
%{SWF::NeedsRecompile->_get_os_paths()} = ();

### First some basic tests

is_deeply([check_files(egfile('foo.txt'))], [], 'invalid filename');
is_deeply([check_files(egfile('foo.swf'))], [egfile('foo.swf')], 'non-existent swf');

unlink egfile('simple.swf');
is_deeply([check_files(egfile('simple.fla'))], [egfile('simple.fla')], 'simple fla');
_touch(egfile('simple.swf'));
push @tempfiles, egfile('simple.swf');
is_deeply([check_files(egfile('simple.fla'))], [], 'simple fla');

unlink egfile('broken.swf');
is_deeply([check_files(egfile('broken.fla'))], [egfile('broken.fla')], 'broken fla');
_touch(egfile('broken.swf'));
push @tempfiles, egfile('broken.swf');
is_deeply([check_files(egfile('broken.fla'))], [egfile('broken.fla')], 'broken fla');

_touch(egfile('missing.swf'));
push @tempfiles, egfile('missing.swf');
is_deeply([check_files(egfile('missing.fla'))], [egfile('missing.fla')], 'missing fla');

### Now the more sophisticated tests

# Set up some bogus file timestamps
my $new = time;
my $middle = $new - 60 * 60;
my $old = $middle - 60 * 60;

my $fla = egfile('example.fla');
my $swf = egfile('example.swf');

_touch($swf);
push @tempfiles, $swf;

# This is a list of "red herrings" which should not trigger the recompile
# Numbers 1 and 4 WILL trigger a recompile because they are in an
#   import exampleN.*;
# which considers all files in that directory to be suspect
my @herrings = (2,3,5,6,7);

# Build an easier-to-use version of the above
my %is_herring = map { egfile('lib', 'example'.$_, 'redherring.as') => 1 } @herrings;

my @files = (
   $fla,
   egfile('lib', 'includetest.as'),
   (map {egfile('lib', 'example'.$_, 'testclass.as')} 1..7),
   (map {egfile('lib', 'example'.$_, 'redherring.as')} 1..7),
);

# For each dependency listed in the @files array, try the check twice:
# once where the SWF is the newest file, and once where the specified
# file is the newest.  The first test should always indicate that
# there is no need for a recompile, while the latter should indicate
# that a recompile is needed unless the dependency is a red herring.

foreach my $file (@files)
{
   utime $old, $old, @files;
   utime $middle, $middle, $swf;
   is(scalar check_files($swf), 0, "check_files, old $file");

   utime $new, $new, $file;
   my $expect = $is_herring{$file} ? 0 : 1;
   is(scalar check_files($swf), $expect, "check_files, new $file");
}

sub _touch
{
   my $name = shift;

   if (! -f $name)
   {
      open my $out_fh, '>', $name or die;
      close $out_fh;
   }
   my $now = time();
   utime $now, $now, $name;
}
