use strict;
use warnings;

use Test::More;

# FILENAME: 03_basic_scanfile.t
# CREATED: 24/03/12 01:01:38 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic scan-for-and-find first-file

use Path::ScanINC;
use FindBin;
use Path::Tiny qw(path);

my $mockroot = path($FindBin::RealBin)->child('mocksystem');

my $orig_inc = [@INC];

my $inc = Path::ScanINC->new(
  immutable => 1,

  # note: libd is intentionally kept out.
  inc => [ map { $mockroot->child($_) . q[] } qw( liba libb libc ) ],
);
{
  my $file = $inc->first_file('.keep');
  isnt( $file, undef, 'find the .keep file in a directory' );
  is( $file->relative($mockroot), $mockroot->child( 'liba', '.keep' )->relative($mockroot), "Find 'liba/.keep' before the rest" );

  note $file;

  my (@files) = $inc->all_files('.keep');
  is( scalar @files, 3, "find exactly 3 .keep files under 3 libs" ) or diag explain \@files;

  note explain \@files;
}
{
  my ($dir) = $inc->first_dir('example1');
  isnt( $dir, undef, 'find a directory named \'example1\' in an INC path' );
  is( $dir->relative($mockroot), $mockroot->child( 'liba', 'example1' )->relative($mockroot), "Find 'liba/example1'" );

  my (@dirs) = $inc->all_dirs('example1');
  is( scalar @dirs, 1, "find exactly 1 example1 dirs under 3 libs" ) or diag explain \@dirs;

  note explain \@dirs;
}

{
  my ($dir) = $inc->first_dir('example2');
  isnt( $dir, undef, 'find a directory named \'example2\' in an INC path' );
  is( $dir->relative($mockroot), $mockroot->child( 'libc', 'example2' )->relative($mockroot), "Find 'libc/example2'" );

  my (@dirs) = $inc->all_dirs('example2');
  is( scalar @dirs, 1, "find exactly 1 example2 dirs under 3 libs" ) or diag explain \@dirs;

  note explain \@dirs;
}

done_testing;

