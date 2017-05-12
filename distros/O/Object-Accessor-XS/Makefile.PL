use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Object::Accessor::XS',
    VERSION_FROM    => 'XS.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 'Object::Accessor' => 0.03, },
    AUTHOR          => 'Richard Soderberg <rsod at cpan.org>',
    ABSTRACT        => 'XS performance improvements for Object::Accessor',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);             
