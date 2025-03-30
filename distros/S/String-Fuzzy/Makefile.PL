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
    NAME                => 'String::Fuzzy',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/String/Fuzzy.pm',
    ABSTRACT_FROM       => 'lib/String/Fuzzy.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'overload'              => 0,
        'parent'                => 0,
        'strict'                => 0,
        'vars'                  => 0,
        'warnings'              => 0,
        # Released 2013-04-26
        'Encode'                => '2.50',
        # Released 2013-03-27
        'Exporter'              => '5.68',
        # Released 2014-10-11
        'Text::Levenshtein::XS' => '0.31',
        # Released 2013-08-01
        'List::Util'            => '1.28',
        # Released 2013-08-01
        'Scalar::Util'          => '1.28',
        # Released 2013-10-05
        'Unicode::Normalize'    => '1.17',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'utf8'              => 0,
        'Test::More'        => '0.98',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    # 2013-03-10
    MIN_PERL_VERSION    => 'v5.14.4',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'String-Fuzzy-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/String-Fuzzy.git',
                web         => 'https://gitlab.com/jackdeguest/String-Fuzzy',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/String-Fuzzy/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

