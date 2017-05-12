use 5.008000;
use ExtUtils::MakeMaker;

if (! have_library('ncap')) {
  warn <<MSG;
-----------------------------------------------------------------------------

Unable to locate the ncap(3) library.

If it is installed in a non-standard location, perhaps try setting the
LIBS environment variable on the command line.

If it is not installed, try downloading and installing the libary from
ftp://ftp.isc.org/isc/ncap/

-----------------------------------------------------------------------------
MSG
  exit;
}

sub have_library {
  my $libname = shift;
  for my $dir (qw( /usr /usr/local )) {
    return 1 if glob("$dir/lib/lib${libname}*");
  }
  return 0;
}

WriteMakefile(
    NAME          => 'Net::Ncap',
    VERSION_FROM  => 'lib/Net/Ncap.pm',
    ABSTRACT_FROM => 'lib/Net/Ncap.pm',
    AUTHOR        => 'Matt Sisk <sisk@cert.org>',
    LIBS          => ['-lncap'],
);
