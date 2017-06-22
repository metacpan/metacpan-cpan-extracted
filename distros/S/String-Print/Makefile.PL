use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.90';

my %prereq  =
  ( Test::More        => 0.86
  , Unicode::GCString => 0
  , Encode            => 0
  , HTML::Entities    => 0
  );

WriteMakefile
  ( NAME      => 'String::Print'
  , VERSION   => $version
  , PREREQ_PM => \%prereq

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'printf extensions'
  , LICENSE   => 'perl'
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/string-print/raw
DISTDIR         = ../public_html/string-print/source
LICENSE         = artistic

# for OODoc's oodist, POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/log-report/
EXTENDS		=

__POSTAMBLE
