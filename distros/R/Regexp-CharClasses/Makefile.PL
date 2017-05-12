#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'Regexp::CharClasses',
    VERSION_FROM         => 'lib/Regexp/CharClasses.pm',
    ABSTRACT_FROM        => 'lib/Regexp/CharClasses.pm',
    PREREQ_PM            => {'strict'    =>  0,
                             'warnings'  =>  0,
                             'charnames' =>  0,
                             'Exporter'  =>  0,},
    MIN_PERL_VERSION     =>  5.010,
    AUTHOR               => 'Abigail <regexp-charclasses@abigail.be>',
    LICENSE              => 'mit',
    META_MERGE           => {
        build_requires   => {'Test::More' => 0,
                             'Exporter'   => 0,
                             'strict'     => 0,
                             'warnings'   => 0,
                            },
        resources        => {
            repository   => 'git://github.com/Abigail/regexp--charclasses.git',
        },
        keywords         => ['regular expression', 'character class'],
    },
);

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
