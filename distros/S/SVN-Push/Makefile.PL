#!/usr/bin/perl
use ExtUtils::MakeMaker;

my $required_svn = '0.37.0';

WriteMakefile(
    AUTHOR              => 'Gerald Richter (richter@dev.ecos.de)',
    ABSTRACT            => 'Push to remote subversion repositories',
    NAME                => 'SVN::Push',
    VERSION_FROM        => 'Push.pm',
    PREREQ_PM           => {
        'SVN::Core'   => $required_svn,
        'URI::Escape' => '0',
    },
    EXE_FILES    => [ 
		'bin/svnpush',
		'bin/svnsetuuid',
		 ],
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);

die "SVN::Core $required_svn must be manually installed"
    unless eval {require SVN::Core} && $SVN::Core::VERSION >= $required_svn;
