use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~  /^experiments$/; # private folder
    return if $file =~  /^doc$/; # private folder
    return if $file =~  /^old$/; # private folder
    return if $file =~  /^tmp$/; # private folder
    return if $file =~  /^bin$/; # private folder
    return if $file =~ /\.lock.*$/; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'Net::API::Nominatim',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Net/API/Nominatim.pm',
    ABSTRACT_FROM    => 'lib/Net/API/Nominatim.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
	'Pod::Markdown' => '0',
	'Pod::Readme' => '0',	
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
	'Test::TempDir::Tiny' => '0',
	'Data::Roundtrip' => '0.30',
	'File::Spec' => '0',
	'FindBin' => '0',
	'LWP::UserAgent' => '0',
	'HTTP::CookieJar::LWP' => '0',
	'Mojo::Log' => '0',
    },
    PREREQ_PM => {
	'Storable' => '0',
	'URI::Escape' => '0',
	'Encode' => '0',
	'HTTP::Request' => '0',
	'IO::Socket::UNIX' => '0',
	'Hash::Merge' => '0',
	'Data::Roundtrip' => '0.30',
	'Mojo::Log' => '0',
	'File::Basename' => '0',
	'HTTP::Cookies' => '0',
	'LWP::UserAgent' => '0',
	'LWP::ConsoleLogger::Easy' => '0',
	'HTTP::CookieJar::LWP' => '0',
	'Cookies::Roundtrip' => '0',
	'Data::Structure::Util' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-API-Nominatim-*' },
    postamble => {
        LIVE_FILES_URL => 'xt/live/url/*.t',
        LIVE_FILES_LOCAL => 'xt/live/local-socket/*.t',
        AUTHOR_FILES => 'xt/author/*.t',
    },
    # Thanks to marto @ Perlmonks.org
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Net::API::Nominatim',
            repository => {
                url  => 'https://github.com/hadjiprocopis/perl-Net-API-Nominatim',
                web  => 'https://github.com/hadjiprocopis/perl-Net-API-Nominatim',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/Net-API-Nominatim/issues',
            }
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    my (undef,%h) = @_;
    return   "LIVE_FILES_LOCAL=$h{LIVE_FILES_LOCAL}\n"
	   . "LIVE_FILES_URL=$h{LIVE_FILES_URL}\n"
	   . "AUTHOR_FILES=$h{AUTHOR_FILES}\n"
	   . <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# this tests with the public nominatim server provided by OSM
livetesturl :: $(LIVE_FILES_URL)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

# this requires a local nominatim server and access to its unix socket
livetestlocal :: $(LIVE_FILES_LOCAL)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

# this just mocks a nominatim server and should not be used really
authortest :: $(AUTHOR_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

POSTAMBLE
}
