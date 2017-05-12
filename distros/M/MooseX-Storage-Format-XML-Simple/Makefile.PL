use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MooseX::Storage::Format::XML::Simple',
    AUTHOR        => 'Bruno Czekay <brunorc@cpan.org>',
    VERSION_FROM  => 'lib/MooseX/Storage/Format/XML/Simple.pm',
    ABSTRACT_FROM => 'lib/MooseX/Storage/Format/XML/Simple.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,
        'Moose::Role'     => 0,
        'MooseX::Storage' => 0,
        'XML::Simple'     => 0
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooseX-Storage-Format-XML-Simple-*' },
);
