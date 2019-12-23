use strict;
use warnings;
use Cwd ();
use File::Basename ();
use Test::More;

my $thisfile = Cwd::abs_path __FILE__;
my $thisdir = File::Basename::dirname($thisfile);

use Path::This qw($THISDIR $THISFILE);

package My::Test::Package1;
use Path::This qw(THISDIR THISFILE);

package My::Test::Package2;
use Path::This qw(&THISDIR &THISFILE);

package main;

is $THISFILE, $thisfile, '$THISFILE';
is $THISDIR, $thisdir, '$THISDIR';
is My::Test::Package1::THISFILE, $thisfile, 'THISFILE';
is My::Test::Package1::THISDIR, $thisdir, 'THISDIR';
is My::Test::Package2::THISFILE(), $thisfile, '&THISFILE';
is My::Test::Package2::THISDIR(), $thisdir, '&THISDIR';

# line 28 "fake-test-file.t"
my $fakefile;
# instantiate at compile time for later symbol import
BEGIN { $fakefile = eval { Cwd::abs_path 'fake-test-file.t' } }

SKIP: { skip 'Failed to resolve nonexistent file', 12 unless length $fakefile;
  my $fakedir = File::Basename::dirname $fakefile;

  is $THISFILE, $thisfile, '$THISFILE unchanged';
  is $THISDIR, $thisdir, '$THISDIR unchanged';
  is My::Test::Package1::THISFILE, $thisfile, 'THISFILE unchanged';
  is My::Test::Package1::THISDIR, $thisdir, 'THISDIR unchanged';
  is My::Test::Package2::THISFILE(), $fakefile, '&THISFILE changed';
  is My::Test::Package2::THISDIR(), $fakedir, '&THISDIR changed';

  Path::This->import(qw($THISDIR $THISFILE));
  package My::Test::Package1;
  # make sure this doesn't run when this block is skipped
  use if length($fakefile), 'Path::This' => qw(THISDIR THISFILE);
  package My::Test::Package2;
  Path::This->import(qw(&THISDIR &THISFILE));
  package main;

  is $THISFILE, $fakefile, '$THISFILE changed';
  is $THISDIR, $fakedir, '$THISDIR changed';
  is My::Test::Package1::THISFILE, $fakefile, 'THISFILE changed';
  is My::Test::Package1::THISDIR, $fakedir, 'THISDIR changed';
  is My::Test::Package2::THISFILE(), $fakefile, '&THISFILE unchanged';
  is My::Test::Package2::THISDIR(), $fakedir, '&THISDIR unchanged';
}

done_testing;
