use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'    => 0,
    'warnings'  => 0,
    'overload'  => 0,
    'Carp'      => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
    'constant'      => 0,
    'base'          => 0,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    NAME         => q[NEXT],
    VERSION_FROM => q[lib/NEXT.pm],
    PREREQ_PM   => { @REQUIRES },
    INSTALLDIRS  => $] >= 5.007003 ? 'perl' : 'site',

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/neilb/next',
                url  => 'https://github.com/neilb/next.git',
            },
        },
    })),

);
