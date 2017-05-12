use 5.004_04;
use ExtUtils::MakeMaker;

use File::Spec;
use ExtUtils::Liblist;

sub have_library {
  my $libname = shift;
  local $SIG{__WARN__} = sub {};
  my $libs = ExtUtils::Liblist->ext("-l$libname", 1, 1);
  return unless ref $libs && @$libs;
  $libs->[0];
}

have_library('wdns') or die "Unable to locate the wdns library.";

my %opt = (
  NAME          => 'Net::WDNS',
  LIBS          => ['-lwdns'],
  INC           => '-I.',
  VERSION_FROM  => 'lib/Net/WDNS.pm',
  ABSTRACT_FROM => 'lib/Net/WDNS.pm',
  AUTHOR        => 'Matt Sisk <sisk@cert.org>',
  PREREQ_PM => {
  },
);

WriteMakefile(%opt);
