use 5.010; #for EUMM versions that do not support MIN_PERL_VERSION
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME             => 'PFT',
    AUTHOR           => q{Giovanni Simoni (dacav at openmailbox)},
    VERSION_FROM     => 'lib/PFT.pm',
    ABSTRACT         => 'Hacker friendly static blog generator',
    LICENSE          => 'gpl_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Cwd'                   => 0,
        'Encode'                => 0,
        'Encode::Locale'        => 0,
        'Exporter'              => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'IO::File'              => 0,
        'Text::Markdown'        => 0,
        'Scalar::Util'          => 0,
        'YAML::Tiny'            => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/dacav/PFT.git',
                web => 'https://github.com/dacav/PFT',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PFT-*' },
);

sub WriteMakefile1 {
    # Compatibility code for old versions of EU::MM.
    # Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

