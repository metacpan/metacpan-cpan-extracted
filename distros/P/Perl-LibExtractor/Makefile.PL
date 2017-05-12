use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text LibExtractor.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Perl::LibExtractor",
    VERSION_FROM => "LibExtractor.pm",
    EXE_FILES    => ["bin/perl-libextractor"],
    PREREQ_PM        => {
       common::sense => 3.4,
       Perl::Strip   => 1.0,
    },
});

$mm->flush;

