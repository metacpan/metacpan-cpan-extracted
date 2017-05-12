use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Mock::Config',
  AUTHOR           => q{Reini Urban <rurban@cpan.org>},
  VERSION_FROM     => 'lib/Mock/Config.pm',
  ABSTRACT_FROM    => 'lib/Mock/Config.pm',
  LICENSE          => 'artistic_2',
  PL_FILES         => {},
  MIN_PERL_VERSION => 5.006,
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0,
  },
  PREREQ_PM => {
    #'ABC'              => 1.6,
    #'Foo::Bar::Module' => 5.0401,
  },
  clean => { FILES => 'Mock-Config-*' },
  SIGN  => 1,
  dist	 => {
    PREOP	=> 'pod2text \$(VERSION_FROM) | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    COMPRESS	=> 'gzip -9v',
    SUFFIX	=> '.gz',
  },
  ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
   ('META_MERGE' =>
    {suggests =>
     {
       'XSConfig' => '6.19',
     },
     resources =>
     {
       license     => 'http://dev.perl.org/licenses/',
       bugtracker  => 'https://github.com/perl11/Mock-Config/issues',
       repository  => 'https://github.com/perl11/Mock-Config',
     },
    }
   ) : ()),
);

package MY;

sub top_targets {
  local $_ = shift->SUPER::top_targets(@_);
  s/\$\(FIRST_MAKEFILE\) blibdirs/\$(FIRST_MAKEFILE\) blibdirs README/;
  $_
}

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
"
}
