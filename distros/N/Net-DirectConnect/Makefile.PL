use ExtUtils::MakeMaker;
#See lib/ExtUtils/MakeMaker.pm for details of how to influence
#the contents of the Makefile that is written.
%_ = (
  NAME         => 'Net::DirectConnect',
  VERSION_FROM => 'lib/Net/DirectConnect.pm',
  INSTALLDIRS  => 'site',
  PREREQ_PM    => {
    'lib::abs'    => 0,
    'Time::HiRes' => 0,
    #'MIME::Base32'        => 0,    #for adc only
    #'Sys::Sendfile'       => 0,    #faster file sending
    'IO::Compress::Bzip2'           => 0,    #preparing filelists
    'DBI'                           => 0,
    'DBD::SQLite'                   => 0,
    'Net::DirectConnect::TigerHash' => 0,
  },
  NORECURS  => 1,
  EXE_FILES => [qw(examples/dcshare examples/dcget examples/dchub)],
);
$_{dist} = {
  PREOP    => "pod2text $_{VERSION_FROM} | tee README >\$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;",
  COMPRESS => 'gzip -9v',
  SUFFIX   => '.gz',
};
#$_{PREREQ_PM}{'Net::DirectConnect::TigerHash'} = 0,    #for sharing and adc
#  $_{NORECURS} = 1, if $^O =~ /win32/i or $^O =~ /mswin/ or $^O =~ /freebsd/i;
if ( $^O !~ /MSWin32/i ) {    #mingw fail
  $_{PREREQ_PM}{$_} = 0 for qw(MIME::Base32);
}
if ( $^O !~ /MSWin32|cygwin/i ) {    #mingw fail
  $_{PREREQ_PM}{$_} = 0 for qw(Sys::Sendfile);
}
WriteMakefile(%_);

sub MY::postamble {
  qq{

#docs: README

#README: $_{VERSION_FROM}
#pod2text $_{VERSION_FROM} > README

fullclean: distclean veryclean
	rm -f \$(DISTNAME)-*.tar.gz *.bak *.old *.core MANIFEST README
	rm -Rf p5-Net-DirectConnect TigerHash lib/Net/DirectConnect/pslib/*.js lib/Net/DirectConnect/pslib/*.css lib/Net/DirectConnect/pslib/psweb.pm

prerelease:

release: prerelease test fullclean manifest metafile dist

tidy:
	perltidy -b -i=2 -ce -l=128 -nbbc -sob -otr -sot *.PL examples/*.pl examples/stat/*.p* examples/stat/*.cgi lib/Net/*.pm lib/Net/DirectConnect/*.pm
}
}

=TODO:
prerelease:
delete !*.pm from psmisc
delete tigerhash

