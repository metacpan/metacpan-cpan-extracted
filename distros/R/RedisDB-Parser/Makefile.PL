use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.3002;
use ExtUtils::CBuilder 0.27;

# Should we build the XS version?
my $make_xs = undef;
$make_xs = 1 if ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
foreach (@ARGV) {
    if (/^-pm/) {
        $make_xs = 0;
    }
    elsif (/^PUREPERL_ONLY=(.*)/) {
        $make_xs = !$1;
    }
}

if ($make_xs) {
    print <<EOM;
*****************************************
* Building XS version of the parser.    *
* If build failed, you can try to       *
* build PP version by running           *
*                                       *
*   perl Makefile.PL PUREPERL_ONLY = 1  *
*   make                                *
*****************************************
EOM
}

WriteMakefile(
    NAME         => 'RedisDB::Parser',
    AUTHOR       => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM => 'lib/RedisDB/Parser.pm',
    ABSTRACT     => 'Redis protocol parser',
    LICENSE      => 'perl',
    PL_FILES     => {},
    OBJECT       => "rdb_parser.o Parser.o",
    PREREQ_PM    => {
        'Try::Tiny' => 0,
        'Encode'    => 2.10,
    },
    BUILD_REQUIRES => {
        'Test::More'         => 0.94,
        'Test::Most'         => 0.22,
        'Test::FailWarnings' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.3002,
        'ExtUtils::CBuilder'  => 0.27,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'RedisDB-Parser-*' },
    META_MERGE => {
        requires => { perl => 5.008004, },
        no_index => {
            file => 'README.pod'
        },
        resources => {

            homepage   => 'https://github.com/trinitum/perl-RedisDB-Parser',
            bugtracker => 'https://github.com/trinitum/perl-RedisDB-Parser/issues',
            repository => 'git://github.com/trinitum/perl-RedisDB-Parser',

            license => 'http://dev.perl.org/licenses/',
        },
        keywords       => [ 'redis', 'protocol', 'parser', ],
        x_contributors => [ 'Pavel Shaydo <zwon@cpan.org>', ],
    },
    CONFIGURE => sub {
        my $hash = $_[1];
        unless ($make_xs) {
            $hash->{XS}     = {};
            $hash->{C}      = [];
            $hash->{OBJECT} = '';
        }
        return $hash;
    },
);
