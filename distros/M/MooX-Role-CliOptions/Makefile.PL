use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'MooX::Role::CliOptions',
    AUTHOR             => q{Jim Bacon <boftx@cpan.org>},
    VERSION_FROM       => 'lib/MooX/Role/CliOptions.pm',
    ABSTRACT_FROM      => 'lib/MooX/Role/CliOptions.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'              => '0',
        'Test::Exception'         => '0',
        'Test::Deep'              => '0',
        'Test::MockModule'        => '0',
        'Capture::Tiny'           => 0,
        'Moo'                     => 0,
        'MooX::StrictConstructor' => 0,
        'Data::Dumper'            => 0,
    },
    PREREQ_PM => {
        'Moo::Role'       => 0,
        'Getopt::Long'    => '2.36',
        'Pod::Usage'      => 0,
        'Carp'            => 0,
        'Types::Standard' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'MooX-Role-CliOptions-*' },
);

__END__
