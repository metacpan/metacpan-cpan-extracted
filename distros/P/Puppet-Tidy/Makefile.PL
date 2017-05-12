use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Puppet::Tidy",
    VERSION_FROM => "lib/Puppet/Tidy.pm",
    AUTHOR    => 'Jasper Lievisse Adriaanse <jasper@mtier.org>',
    ABSTRACT  => 'Tidy up your Puppet manifests',
    EXE_FILES => ['bin/puppet-tidy.pl'],
    LICENSE   => 'ISC',
    PREREQ_PM =>
    {
	'File::Copy' => 0,
	'Text::Tabs' => 0,
    },
    dist      => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
