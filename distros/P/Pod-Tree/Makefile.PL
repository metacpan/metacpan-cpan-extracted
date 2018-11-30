use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config = (
    NAME         => 'Pod::Tree',
    VERSION_FROM => 'lib/Pod/Tree.pm',    # finds $VERSION
    DISTNAME     => 'Pod-Tree',
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Pod/Tree.pm',
            AUTHOR        => 'Steven McDougall (swmcd@world.std.com)'
            )
        : ()
    ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),

    clean => {
        FILES =>
            "t/pod2html.d/*.html* t/pods2html.d/A t/pods2html.d/html_act* t/pods2html.d/podR/HTML t/*/*.act lib/Pod/Tree/*~"
    },
    dist => {
        COMPRESS => 'gzip --best',
        SUFFIX   => '.gz'
    },
    EXE_FILES => [qw(mod2html podtree2html pods2html perl2html)],
    PREREQ_PM => {
        'File::Find'     => 1,
        'HTML::Stream'   => 1.49,
        'IO::File'       => 1,
        'IO::String'     => 1,
        'Pod::Escapes'   => 1.02,
        'Text::Template' => 1,
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? (
            META_MERGE => {
            	'meta-spec' => { version => 2 },
            	resources   => {
            		repository => {
            			type => 'git',
            			url  => 'http://github.com/manwar/Pod-Tree.git',
            			web  => 'http://github.com/manwar/Pod-Tree',
            		},
            		bugtracker => {
            			web => 'http://github.com/manwar/Pod-Tree/issues',
            		},
            		homepage => 'http://metacpan.org/pod/Pod::Tree',
            	},
            }
             )
        : ()
    )
);

my %test_requires = (
    'Test::More'    => 1,
    'Test::Compile' => '1.2.1',
    'Path::Tiny'    => '0.105',
);

if ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ) {
    $config{TEST_REQUIRES} = \%test_requires;
}
else {
    $config{BUILD_REQUIRES} = \%test_requires;
}

WriteMakefile(%config);

