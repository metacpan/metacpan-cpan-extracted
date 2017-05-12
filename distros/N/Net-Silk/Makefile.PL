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
  LIBS   => ['-lsilk'],
  INC    => '-I.',
  OBJECT => '$(O_FILES)',
);

for my $l (qw( silk )) {
  my $p = find_lib($l);
  if ($p) {
    my @p = File::Spec->splitdir($p);
    pop @p;
    my $libdir = File::Spec->catdir(@p);
    $options{LIBS}[0] = "-L$libdir $options{LIBS}[0]";
    pop @p;
    my $incdir = File::Spec->catdir(@p, 'include');
    for my $d ($incdir, File::Spec->catdir($incdir, $l)) {
      my $f = File::Spec->catdir($d, "$l.h");
      if (-f $f) {
        $options{INC} .= " -I$incdir";
        last;
      }
    }
    next;
  }
  my $dirs = join("\n    ", @DynaLoader::dl_library_path);
  warn <<__FAIL and exit;
The $l(3) library was not found in the following directories:

    $dirs

If it is installed but in an odd location, consider setting
the LD_LIBRARY_PATH environment variable to the lib dir.
__FAIL
}

WriteMakefile(
  NAME          => 'Net::Silk',
  VERSION_FROM  => 'lib/Net/Silk.pm',
  #ABSTRACT_FROM => 'lib/Net/Silk.pm',
  AUTHOR        => 'Matt Sisk <sisk@cert.org>',
  PREREQ_PM => {
    'DateTime'          => 0,
    'Math::Int64'       => '0.51',
    'Math::Int128'      => '0.21',
  },
  %options
);
