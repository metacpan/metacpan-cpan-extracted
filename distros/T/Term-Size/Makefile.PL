
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

die q{OS unsupported\n} if $^O =~ /MSWin/i;

my %META = (
    'dynamic_config' => 0,
    'meta-spec'      => { version => 2 },
    'prereqs'        => {
        develop => {
            requires => {    # author tests
                'Test::Pod' => '1.18',
            }
        },
    },
    'resources' => {
        repository => {
            type => 'git',
            url  => 'git://github.com/aferreira/cpan-Term-Size.git',
            web  => 'https://github.com/aferreira/cpan-Term-Size'
        },
        bugtracker => {
            web => 'https://github.com/aferreira/cpan-Term-Size/issues',
        },
    },
);

WriteMakefile(
    NAME   => 'Term::Size',
    AUTHOR => [
        'Tim Goodwin <tim@uunet.pipex.com>',
        'Adriano Ferreira <ferreira@cpan.org>'
    ],
    VERSION_FROM  => 'Size.pm',
($] >= 5.005 ? (
    ABSTRACT_FROM => 'Size.pm',
) : ()),
($EUMM_VERSION >= 6.3001 ? (
    LICENSE       => 'perl',
) : ()),
($EUMM_VERSION >= 6.4501 ? (
    META_MERGE    => \%META,
) : ()),
($EUMM_VERSION >= 6.6303 ? (
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
) : ()),
    PREREQ_PM => {
        'strict'     => 0,
        'DynaLoader' => 0,
        'Exporter'   => 0,
        'vars'       => 0,
($EUMM_VERSION < 6.6303 ? (
        'Test::More' => 0,    # test
) : ()),
    },
);
