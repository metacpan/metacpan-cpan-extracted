use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => "Template::Plugin::Number::Format",
    'VERSION_FROM' => "Format.pm",
    'PREREQ_PM'    => {
        "Template"          => 2.07,
        "Number::Format"    => 0,
    },
    clean => {
        FILES => 'Template-Plugin-Number-Format-$(VERSION).tar.gz',
    },
    dist => {
        PREOP => 'perldoc -t Format.pm > README',
    },
);
