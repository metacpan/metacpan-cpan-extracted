#
# Copyright (C) 2008 DMA.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Scanner',
    'DISTNAME'  => 'Scanner',
    'ABSTRACT'  => 'Classes for handling page Scanning.',
    'AUTHOR'    => 'Dale Amon',
    'VERSION_FROM' => 'Version',
    'PREREQ_PM' => {'Exporter' => 0, 'POSIX' => 0, 'File::Spec' => 0,
		    'Document::LogFile' => 0, 'Document::TocFile' => 0,
		    'Document::Toc' => 0, 'Document::PageIterator' => 0,
		    'File::Spec::PublicationPage' => 0 },
    'dist'      => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
    'clean'     => {FILES => "*/*/*~ *~ .#* */*/.#*"},
);


