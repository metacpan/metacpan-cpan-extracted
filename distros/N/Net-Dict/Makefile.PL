#
# Makefile.PL for Net-Dict
#
#

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

&WriteMakefile(
    NAME		=> 'Net::Dict',
    DISTNAME	=> 'Net-Dict',
    VERSION_FROM	=> 'lib/Net/Dict.pm',
    PREREQ_PM	=> {
                     'IO::Socket'     => 0,
                     'Net::Cmd'	      => 0,
                     'Carp'		      => 0,
                     'AppConfig::Std' => 0,
                    },
    EXE_FILES	=> [qw(dict tkdict)],
    AUTHOR		=> 'Neil Bowers <neil@bowers.com>',
    ABSTRACT_FROM	=> 'lib/Net/Dict.pod',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/neilbowers/Net-Dict',
        },
        no_index => {
            package => ['Net::Dict::TestConfig'],
        }
    },
    LICENSE      => 'perl',
    dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test::More' => 0.88,
                'Test::Differences' => 0.62,
                'Test::RequiresInternet' => 0.05,
          })
        : ()
    ),

);

