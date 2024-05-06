use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::distsignature
{
    return <<'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

WriteMakefile(
    NAME                => 'Module::Generic',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Module/Generic.pm',
    ABSTRACT_FROM       => 'lib/Module/Generic.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'common::sense'         => 0,
        'overload'              => 0,
        'overloading'           => 0,
        'parent'                => 0,
        'strict'                => 0,
        'utf8'                  => 0,
        'version'               => 0,
        'warnings'              => 0,
        'Class::Load'           => '0.25',
        'Clone'                 => '0.43',
        'Config'                => 0,
        'Data::Dump'            => '1.23',
        'Data::UUID'            => '1.226',
        'DateTime'              => '1.57',
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::TimeZone'    => '2.51',
        'DateTime::TimeZone::Catalog::Extend' => 'v0.3.0',
        'Devel::StackTrace'     => 0,
        'Encode'                => 0,
        'Exporter'              => '5.70',
        # Used to require 1.13, but removed any requirement
        'Fcntl'                 => 0,
        'File::Basename'        => '2.85',
        # Previously requiring 2.34, but removing any requirement. Let's see.
        'File::Copy'            => 0,
        # Same as File::Copy, this is a core module
        'File::DosGlob'         => 0,
        'File::Glob'            => 0,
        # Only load it, if it exists
        # 'File::MMagic::XS' => '0.09008',
        'File::MMagic'          => '1.30',
        'File::Spec'            => '3.73',
        # Core module
        'I18N::Langinfo'        => '0.21',
        'IO::Dir'               => '1.41',
        'IO::File'              => '1.41',
        'IO::Scalar'            => '2.113',
        'IPC::SysV'             => '2.09',
        'JSON'                  => '4.03',
        'JSON::XS'              => '4.03',
        'List::Util'            => '1.56',
        'Module::Metadata'      => '1.000037',
        'POSIX'                 => '1.53_01',
        'Regexp::Common'        => '2017060201',
        'Scalar::Util'          => '1.50',
        'Storable::Improved'    => 'v0.1.3',
        'Sub::Util'             => '1.54',
        'Tie::Hash'             => '1.05',
        'URI::Escape'           => '5.09',
        'URI::file'             => '5.09',
        'Want'                  => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Bytes::Random::Secure' => '0.29',
        'Cwd'           => '3.72',
        'Encode'        => '3.08',
        'File::Find'    => 0,
        'File::Which'   => '1.23',
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'Test::Time'    => 0,
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
        'utf8'          => 0,
        'open'          => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Module-Generic-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Module-Generic.git',
                web         => 'https://gitlab.com/jackdeguest/Module-Generic',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Module-Generic/issues',
            },
        },
    }) : ()),
);
