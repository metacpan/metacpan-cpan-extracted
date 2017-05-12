use strict;
use warnings;
use ExtUtils::MakeMaker;
 

my $mm_ver = $ExtUtils::MakeMaker::VERSION;

if ($mm_ver =~ /_/) { # dev version

    $mm_ver = eval $mm_ver;

    die $@ if $@;

}


WriteMakefile(
    NAME                => 'Orignal',
    AUTHOR              => q{John Scoles <byterock@hotmail.com>},
    VERSION_FROM        => 'lib/Orignal.pm',
    ABSTRACT_FROM       => 'lib/Orignal.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'open_source')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Orignal-*' },



($mm_ver <= 6.45

        ? ()

        : (META_MERGE => {
            'meta-spec' => { version => 2 },

            resources => {

                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Orignal',

                repository  => {

                    type => 'git',

                    web  => 'https://github.com/byterock/Orignal',

                    url  => 'git://github.com/byterock/Orignal.git',

                },

            },

          })

    ),


 ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006001)
        : ()
    ),);
