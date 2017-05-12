#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile1(

    NAME            => 'PAR',
    VERSION_FROM    => 'lib/PAR.pm',
    ABSTRACT_FROM   => 'lib/PAR.pm',
    LICENSE         => 'perl_5',
    AUTHOR          => [ 'Audrey Tang <cpan@audreyt.org>' ],

    MIN_PERL_VERSION => '5.008001',
    PREREQ_PM       => {
        'File::Temp'     => '0.05',
        'Compress::Zlib' => ($^O eq 'MSWin32') ? '1.16' : '1.30',
        'Archive::Zip'   => '1.00',
        'PAR::Dist'      => '0.32',
        'AutoLoader'     => '5.66_02',
        'Digest::SHA'    => '5.45',
    },
    TEST_REQUIRES   => {
      'Test::More'       => 0,
    },

    META_MERGE      => {
      'meta-spec'        => { version => 2 },
      resources          => {
        repository  => {
          type => 'git',
          url  => 'git://github.com/rschupp/PAR.git',
          web  => 'https://github.com/rschupp/PAR',
        },
        MailingList => 'par@perl.org',
      },
    },

    clean           => { FILES => 't/hello.par' },
);


sub MY::postamble {
    return <<'...';
pure_all :: t/hello.par
t/hello.par:
	$(PERL) t/gen-hello-par.pl
...
}

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

