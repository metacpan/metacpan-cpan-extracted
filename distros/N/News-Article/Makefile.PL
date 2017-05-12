use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (NAME         => 'News::Article',
	       DISTNAME     => 'News-Article',
               VERSION_FROM => 'Article.pm',
	       dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' });
