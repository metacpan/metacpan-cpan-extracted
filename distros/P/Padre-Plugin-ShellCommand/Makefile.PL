use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O =~ m/^(?:mswin32|dos)$/i) {
    die "NA: OS probably not supported, no point installing this module\n";
}

WriteMakefile(
    NAME                => 'Padre::Plugin::ShellCommand',
    AUTHOR              => q{Gregory Siems <gsiems@gmail.com>},
    VERSION_FROM        => 'lib/Padre/Plugin/ShellCommand.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/ShellCommand.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Which' => 0,
        'Padre'      => 0.43,
        'Padre::Plugin::Shell::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-ShellCommand-*' },
);
