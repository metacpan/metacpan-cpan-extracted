eval "use Curses;";
if ($@) {
    print "\a",<<'MSG';
*** Error:
    The Curses-module is not installed.
    If you want to use Perl ASCII Widgets(Paw),
    then you'll need to install Perl-Curses,
    you can find Curses at:
    ftp://ftp.cpan.org/pub/CPAN/authors/id/WPS/Curses-1.02.tar.gz
MSG
    exit;
}

use ExtUtils::MakeMaker;
$verbose = 1;
WriteMakefile(
  NAME => "Paw",
  DISTNAME => "Paw",
  VERSION_FROM => 'Paw.pm',
  MAN1PODS => { },
  MAN3PODS => { },
  'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
);
