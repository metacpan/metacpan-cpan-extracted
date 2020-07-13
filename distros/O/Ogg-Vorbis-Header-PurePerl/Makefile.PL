use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'    => 0,
    'warnings'  => 0,
    'constant'  => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
	'NAME'		=> 'Ogg::Vorbis::Header::PurePerl',
	'VERSION_FROM'	=> 'lib/Ogg/Vorbis/Header/PurePerl.pm',

	'PREREQ_PM'		=> { @REQUIRES },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

	($] >= 5.005 ?
	(ABSTRACT_FROM => 'lib/Ogg/Vorbis/Header/PurePerl.pm',
	AUTHOR     => 'Dan Sully <daniel@cpan.org>') : ()),

    ($mm_ver >= 6.31
        ? (LICENSE => 'gpl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/dsully/perl-ogg-vorbis-header-pureperl',
                    url  => 'https://github.com/dsully/perl-ogg-vorbis-header-pureperl.git',
                },
            },
          })
    ),

);
