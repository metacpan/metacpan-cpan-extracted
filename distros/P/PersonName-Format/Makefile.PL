use ExtUtils::MakeMaker;
use strict;
use warnings;

# Check for a C compiler. XS is optional: if unavailable, the pure-Perl
# fallback in PersonName::Format::PP is used automatically.
my $has_cc = eval
{
    require ExtUtils::CBuilder;
    my $b = ExtUtils::CBuilder->new( quiet => 1 );
    $b->have_compiler;
};

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

# Add inc/ to @INC during testing so stub modules are found.
sub MY::test_via_harness
{
    my( $self, $perl, $tests ) = @_;
    return( qq{\t$perl "-Iinc" "-Iblib/lib" "-Iblib/arch" }
          . qq{"-MExtUtils::Command::MM" "-MTest::Harness" }
          . qq{-e "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" }
          . qq{$tests\n} );
}

sub MY::test_via_script
{
    my( $self, $perl, $tests ) = @_;
    return( qq{\t$perl "-Iinc" "-Iblib/lib" "-Iblib/arch" $tests\n} );
}

my %WriteMakefileArgs = (
    NAME                => 'PersonName::Format',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/PersonName/Format.pm',
    ABSTRACT_FROM       => 'lib/PersonName/Format.pm',
    PL_FILES            => {},
    XS                  => { 'PersonName-Format.xs' => 'PersonName-Format.c' },
    OBJECT              => 'PersonName-Format$(OBJ_EXT)',
    # 2009-08-23
    MIN_PERL_VERSION    => 'v5.10.1',
    LICENSE             => 'perl_5',
    PREREQ_PM           =>
    {
        'parent'                    => 0,
        'strict'                    => 0,
        'vars'                      => 0,
        'warnings'                  => 0,
        'warnings::register'        => 0,
        'Locale::Unicode'           => 'v0.4.3',
        'Locale::Unicode::Data'     => 'v1.9.0',
        'Scalar::Util'              => 0,
        'Unicode::UCD'              => 0,
        'Wanted'                    => 'v0.1.2',
        'XSLoader'                  => 0,
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'open'              => 0,
        'utf8'              => 0,
        'File::Spec'        => 0,
        'File::Temp'        => 0,
        'Test::More'        => '1.302120',
        'Test::Pod'         => '1.52',
        # On Perl 5.14+, JSON::PP is in core. We still auto-detect faster backends
        # (Cpanel::JSON::XS, JSON::XS) at runtime in DateTime::Lite::TimeZone, but neither
        # is required.
        ( $] < 5.014
            # 2010-04-02
            ? ( 'JSON' => '2.20' )
            : ()
        ),
    },
    ( $has_cc
        ? (
            XS      => { 'PersonName-Format.xs' => 'PersonName-Format.c' },
            OBJECT  => 'PersonName-Format$(OBJ_EXT)',
        )
        : ()
    ),
    INC     => '-I.',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean   => { FILES => 'PersonName-Format-* PersonName-Format.c PersonName-Format$(OBJ_EXT) nytprof nytprof.out' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        no_index       =>
        {
            directory => [ 't', 'inc' ],
        },
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:deguest/PersonName-Format.git',
                web         => 'https://gitlab.com/deguest/PersonName-Format',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/deguest/PersonName-Format/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

