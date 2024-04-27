use ExtUtils::MakeMaker;
use strict;
use warnings;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'Promise::Me',
    VERSION_FROM        => 'lib/Promise/Me.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT_FROM       => 'lib/Promise/Me.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'curry'         => 0,
        'parent'        => 0,
        'strict'        => 0,
        'vars'          => 0,
        'warnings'      => 0,
        'Clone'         => '0.45',
        'Config'        => 0,
        'Errno'         => 0,
    	'Filter::Util::Call' => '1.59',
        'Module::Generic' => 'v0.35.4',
        'Nice::Try'     => 'v1.3.10',
        'PPI'           => '1.278',
        'POSIX'         => 0,
        'Scalar::Util'  => '1.50',
        # 'Storable'      => '3.15',
        'Storable::Improved' => 'v0.1.3',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Module::Generic::File' => 'v0.8.1',
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'Time::HiRes'   => 0,
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.14.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Promise-Me-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Promise-Me.git',
                web         => 'https://gitlab.com/jackdeguest/Promise-Me',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Promise-Me/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

