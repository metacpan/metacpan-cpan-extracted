use 5.026;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Glob qw(bsd_glob);

# Repository URL: edit before release if you fork under another org/user.
my $REPO_WEB = 'https://github.com/neo1ite/Modern-OpenAPI-Generator';
my $REPO_GIT = "$REPO_WEB.git";

my @test_files = sort( bsd_glob('t/*.t'), bsd_glob('t/unit/*.t') );

WriteMakefile(
    NAME             => 'Modern::OpenAPI::Generator',
    VERSION_FROM     => 'lib/Modern/OpenAPI/Generator.pm',
    ABSTRACT         => 'Generate Mojolicious-friendly OpenAPI 3.x clients and servers',
    AUTHOR           => 'Modern::OpenAPI::Generator contributors',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.026',
    EXE_FILES        => ['bin/oapi-perl-gen'],
    PREREQ_PM        => {
        'YAML::PP'         => '0.034',
        'JSON::MaybeXS'    => '1.004',
        'OpenAPI::Modern'  => '0.060',
        'Mojolicious'      => '9.0',
        'Moo'              => '2.005',
        'Types::Standard'  => '2.000',
        'Getopt::Long'     => '2.54',
        'Pod::Usage'       => 0,
        'Path::Tiny'       => '0.144',
        'Carp'             => 0,
        'File::Path'       => '2.08',
        'Storable'         => '3.08',
    },
    TEST_REQUIRES    => {
        'Test::More' => '0.96',
        'Test::Pod'  => '1.00',
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources   => {
            homepage   => $REPO_WEB,
            bugtracker => {
                web => "https://github.com/neo1ite/Modern-OpenAPI-Generator/issues",
            },
            repository => {
                type => 'git',
                url  => $REPO_GIT,
                web  => $REPO_WEB,
            },
        },
    },
    test => { TESTS => join( ' ', @test_files ) },
);

# BEGIN PREPARE4RELEASE_POSTAMBLE
sub MY::postamble {
  return '' if !-e '.git';
  <<'PREPARE4RELEASE_POD2README';
pure_all :: README.md

README.md : $(VERSION_FROM)
	pod2github $< $@
	$(PERL) maint/inject-readme-badges.pl
PREPARE4RELEASE_POD2README
}
# END PREPARE4RELEASE_POSTAMBLE
