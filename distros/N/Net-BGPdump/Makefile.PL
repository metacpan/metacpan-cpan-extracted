use 5.004_04;
use ExtUtils::MakeMaker;
use DynaLoader;
use File::Spec;

use strict;
use warnings;

sub find_lib {
  die "lib name required" unless @_;
  my @locs = DynaLoader::dl_findfile('-l' . shift);
  @locs ? $locs[0] : '';
}

my %options = (
  LIBS   => ['-lbgpdump'],
  INC    => '-I.',
);

my $l = "bgpdump";
my $p = find_lib($l);
if ($p) {
  my @p = File::Spec->splitdir($p);
  pop @p;
  my $libdir = File::Spec->catdir(@p);
  pop @p;
  my $incdir = File::Spec->catdir(@p, 'include');
  my $f = File::Spec->catdir($incdir, "${l}_lib.h");
  $options{INC} .= " -I$incdir" if -f $f;
  $options{LIBS}[0] = "-L$libdir $options{LIBS}[0]";
}
else {
  my $dirs = join("\n    ", @DynaLoader::dl_library_path);
  warn <<__FAIL and exit;
The $l library was not found in the following directories:

    $dirs

If it is installed but in an odd location, consider setting
the LD_LIBRARY_PATH environment variable to the lib dir.
__FAIL
}

WriteMakefile(
  NAME          => 'Net::BGPdump',
  VERSION_FROM  => 'lib/Net/BGPdump.pm',
  ABSTRACT_FROM => 'lib/Net/BGPdump.pm',
  AUTHOR        => 'Matt Sisk <sisk@cert.org>',
  %options
);
