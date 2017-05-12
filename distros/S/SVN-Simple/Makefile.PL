#!/usr/bin/perl
use ExtUtils::MakeMaker;

my $required_svn = '0.31.0';

WriteMakefile(
    AUTHOR              => 'Chia-liang Kao (clkao@clkao.org)',
    ABSTRACT            => 'Simple interface to SVN::Delta::Editor',
    NAME                => 'SVN::Simple::Edit',
    VERSION_FROM        => 'lib/SVN/Simple/Edit.pm',
    DISTNAME            => 'SVN-Simple',
    PREREQ_PM           => {
#        'SVN::Core'   => $required_svn,
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);

$::VERSION = $required_svn;
die << "." unless eval {require SVN::Core; SVN::Core->VERSION >= main->VERSION };
===> Warning: SVN::Core missing or outdated.
Please manually install SVN::Core by compiling Subversion
(version $required_svn or above) with SWIG/Perl bindings,
and try this installation process again.
.
