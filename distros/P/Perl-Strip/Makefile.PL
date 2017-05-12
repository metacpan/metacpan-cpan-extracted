use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text Strip.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Perl::Strip",
    VERSION_FROM => "Strip.pm",
    EXE_FILES    => ["bin/perlstrip"],
    PREREQ_PM        => {
       PPI           => 1.213,
       Digest::MD5   => 2,
       common::sense => 3.3,
    },
});

$mm->flush;

