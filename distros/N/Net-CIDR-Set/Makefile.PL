require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Net::CIDR::Set',
    'AUTHOR'        => 'Robert Rothenberg <rrwo@cpan.org>',
    'ABSTRACT_FROM' => 'lib/Net/CIDR/Set.pm',
    'VERSION_FROM'  => 'lib/Net/CIDR/Set.pm',
    "LICENSE"       => "perl",
    'PREREQ_PM'     => {
        'Carp'             => 0,
        'overload'         => 0,
        'strict'           => 0,
        'warnings'         => 0
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    'SIGN'        => 1,
    'META_MERGE'  => {
        resources    => {
            repository => 'git://github.com/robrwo/perl-Net-CIDR-Set.git',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set',
        },
    }
);
